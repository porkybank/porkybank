defmodule Porkybank.Workers.TransactionFetcher do
  require Logger

  use Oban.Worker, queue: :default, max_attempts: 3

  import Ecto.Query

  alias Oban
  alias Phoenix.PubSub
  alias Porkybank.Banking.PlaidAccount
  alias Porkybank.IgnoredTransactions

  @impl true
  def perform(%{args: %{"user_id" => user_id} = args}) do
    try do
      # Ensure no duplicate jobs for this user are running or scheduled
      if has_existing_jobs?(user_id) do
        Logger.info(
          "Skipping job creation: user #{user_id} already has a running or scheduled job"
        )

        :ok
      end

      today = Date.utc_today()

      {:ok, first_day_of_month} =
        today |> Date.beginning_of_month() |> NaiveDateTime.new(~T[00:00:00])

      user = Porkybank.Accounts.get_user!(user_id) |> Porkybank.Repo.preload(:plaid_accounts)

      new_transactions = Porkybank.PlaidClient.get_plaid_transactions(user)

      old_transactions_ids =
        Porkybank.Banking.PlaidTransaction
        |> where([t], t.user_id == ^user_id and t.inserted_at >= ^first_day_of_month)
        |> select([t], t.transaction_id)
        |> Porkybank.Repo.all()

      new_transactions_filtered =
        Enum.filter(new_transactions, fn new_transaction ->
          !Enum.member?(old_transactions_ids, new_transaction["transaction_id"])
        end)

      new_transactions_ids =
        Enum.reduce(new_transactions_filtered, [], fn tx, acc ->
          case maybe_confirm_pending_transaction(tx) do
            :insert ->
              {:ok, inserted_transaction} =
                Porkybank.Banking.PlaidTransaction.changeset(
                  %Porkybank.Banking.PlaidTransaction{},
                  tx
                )
                |> Ecto.Changeset.put_assoc(:user, user)
                |> Porkybank.Repo.insert()

              if maybe_ignore_transaction(tx) do
                IgnoredTransactions.create(tx["transaction_id"], user)
                acc
              else
                [inserted_transaction.id | acc]
              end

            :ignore ->
              acc
          end
        end)

      case Porkybank.OpenAI.match_new_transactions_with_recurring_transactions(
             user,
             new_transactions_ids,
             today
           ) do
        %{"matching_transactions" => matching_transactions} ->
          Enum.each(matching_transactions, fn transaction ->
            %{
              "transaction_id" => transaction_id,
              "confidence_score" => confidence_score,
              "matched_expense_id" => matched_expense_id
            } = transaction

            if confidence_score == "HIGH" do
              IgnoredTransactions.create(transaction_id, user,
                reason: "AI matched",
                matched_expense_id: matched_expense_id
              )
            end
          end)

        %{} ->
          Logger.info("No matching transactions found")

        _ ->
          Logger.error("Error matching new transactions with recurring transactions")
      end

      Porkybank.Repo.update_all(
        PlaidAccount |> where(user_id: ^user.id),
        set: [last_synced_at: NaiveDateTime.utc_now()]
      )

      PubSub.broadcast(
        Porkybank.PubSub,
        "transactions_updated_#{user_id}",
        {:updated_transactions}
      )

      args
      |> new(schedule_in: 20 * 60)
      |> Oban.insert!()

      :ok
    rescue
      error ->
        Logger.error("Error fetching transactions for user #{user_id}: #{inspect(error)}")

        Logger.info("Retrying in 20 minutes")

        args
        |> new(schedule_in: 20 * 60)
        |> Oban.insert!()

        raise error
    end
  end

  def resync(user_id) do
    Oban.Job
    |> where(
      [j],
      j.worker == "Porkybank.Workers.TransactionFetcher" and
        fragment("?->>'user_id' = ?", j.args, ^Integer.to_string(user_id))
    )
    |> Oban.cancel_all_jobs()

    Oban.insert(Porkybank.Workers.TransactionFetcher.new(%{user_id: user_id}))
  end

  def resync_all_users() do
    try do
      Oban.Job
      |> where([j], j.worker == "Porkybank.Workers.TransactionFetcher")
      |> Oban.cancel_all_jobs()

      Porkybank.Banking.PlaidAccount
      |> select([a], a.user_id)
      |> Porkybank.Repo.all()
      |> Enum.each(fn account ->
        Oban.insert(Porkybank.Workers.TransactionFetcher.new(%{user_id: account}))
      end)

      :ok
    rescue
      error ->
        Logger.error("Error resyncing all users: #{inspect(error)}")
        raise error
    end
  end

  def maybe_confirm_pending_transaction(%{
        "pending_transaction_id" => pending_transaction_id,
        "amount" => amount
      }) do
    # no pending transaction id, so we should insert
    if pending_transaction_id == nil do
      :insert
    else
      # if we have a pending transaction, we should confirm it and update the amount
      # and then ignore the new transaction
      if pending_transaction =
           Porkybank.Repo.get_by(Porkybank.Banking.PlaidTransaction,
             transaction_id: pending_transaction_id
           ) do
        Porkybank.Banking.PlaidTransaction.changeset(pending_transaction, %{
          pending: false,
          amount: amount
        })

        :ignore
      else
        :insert
      end
    end
  end

  def has_existing_jobs?(user_id) do
    Oban.Job
    |> where(
      [j],
      j.worker == "Porkybank.Workers.TransactionFetcher" and
        fragment("?->>'user_id' = ?", j.args, ^Integer.to_string(user_id))
    )
    |> Porkybank.Repo.exists?()
  end

  def maybe_ignore_transaction(%{
        "amount" => amount,
        "personal_finance_category" => %{"detailed" => category}
      }) do
    amount < 0 or category == "LOAN_PAYMENTS_CREDIT_CARD_PAYMENT"
  end
end
