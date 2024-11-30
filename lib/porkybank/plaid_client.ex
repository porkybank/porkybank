defmodule Porkybank.PlaidClient do
  use Tesla

  import Ecto.Query

  plug Tesla.Middleware.BaseUrl,
       Keyword.get(Application.get_env(:porkybank, Porkybank.PlaidClient), :base_url)

  plug Tesla.Middleware.JSON

  def base_request do
    %{
      client_id: Keyword.get(Application.get_env(:porkybank, __MODULE__), :client_id),
      secret: Keyword.get(Application.get_env(:porkybank, __MODULE__), :secret)
    }
  end

  def get_plaid_transactions(%Porkybank.Accounts.User{} = user, opts \\ []) do
    access_tokens = get_access_tokens(user)
    today = Keyword.get(opts, :date) || Date.utc_today()
    first_day_of_month = today |> Date.beginning_of_month() |> Date.to_iso8601()
    last_day_of_month = today |> Date.end_of_month() |> Date.to_iso8601()

    Enum.reduce(access_tokens, [], fn access_token, txs ->
      case post(
             "/transactions/get",
             Map.merge(base_request(), %{
               access_token: access_token,
               start_date: first_day_of_month,
               end_date: last_day_of_month
             }),
             headers: [{"content-type", "application/json"}]
           ) do
        {:ok, %{status: 400}} ->
          txs

        {:ok, %{body: %{"transactions" => transactions}}} ->
          txs ++ transactions

        {:error, %{"error_message" => error_message}} ->
          error_message
      end
    end)
  end

  def get_plaid_accounts(user) do
    accounts = Porkybank.Banking.PlaidAccount |> where(user_id: ^user.id) |> Porkybank.Repo.all()

    Enum.reduce(accounts, [], fn account, acc ->
      case post(
             "/accounts/get",
             Map.merge(base_request(), %{access_token: account.access_token}),
             headers: [{"content-type", "application/json"}]
           ) do
        {:ok, %{status: 400}} ->
          acc

        {:ok, %{body: %{"accounts" => accounts}}} ->
          acc ++
            [
              %{
                id: account.id,
                inserted_at: account.inserted_at,
                institution_name: account.institution_name,
                last_synced_at: account.last_synced_at,
                accounts: accounts
              }
            ]

        {:error, %{"error_message" => error_message}} ->
          {:error, error_message}
      end
    end)
  end

  def get_transactions(user, opts \\ []) do
    today = Keyword.get(opts, :date) || Date.utc_today()
    first_day_of_month = Porkybank.Utils.get_first_day_of_month(today)
    last_day_of_month = Porkybank.Utils.get_last_day_of_month(today)

    user_has_transaction_in_month? =
      case Porkybank.Banking.PlaidTransaction
           |> where(user_id: ^user.id)
           |> where([t], t.date >= ^first_day_of_month and t.date <= ^last_day_of_month)
           |> Porkybank.Repo.all() do
        [] -> false
        _ -> true
      end

    ignored_transactions =
      Porkybank.Banking.IgnoredTransaction
      |> where(user_id: ^user.id)
      |> Porkybank.Repo.all()

    transactions =
      if !user_has_transaction_in_month? do
        get_plaid_transactions(user, opts)
        |> Enum.map(fn tx ->
          Porkybank.Banking.PlaidTransaction.changeset(
            %Porkybank.Banking.PlaidTransaction{},
            tx
          )
          |> Ecto.Changeset.put_assoc(:user, user)
          |> Porkybank.Repo.insert!()
        end)
      else
        Porkybank.Banking.PlaidTransaction
        |> where(user_id: ^user.id)
        |> where([t], t.date >= ^first_day_of_month and t.date <= ^last_day_of_month)
        |> Porkybank.Repo.all()
      end

    calculate_totals(transactions, ignored_transactions, today)
  end

  def get_access_token(public_token) do
    request_body = Map.merge(base_request(), %{public_token: public_token})

    case post("/item/public_token/exchange", request_body,
           headers: [{"content-type", "application/json"}]
         ) do
      {:ok, %{body: %{"access_token" => access_token}}} ->
        access_token

      {:error, %{"error_message" => error_message}} ->
        error_message
    end
  end

  def get_link_token(user) do
    request_body =
      Map.merge(base_request(), %{
        client_name: "Porkybank",
        country_codes: [
          "US"
        ],
        language: "en",
        products: ["transactions"],
        user: %{
          client_user_id: Integer.to_string(user.id),
          email: user.email
        },
        account_filters: %{
          depository: %{
            account_subtypes: ["checking", "savings"]
          },
          credit: %{
            account_subtypes: ["credit card"]
          }
        }
      })

    post("/link/token/create", request_body, headers: [{"content-type", "application/json"}])
  end

  defp calculate_totals(transactions, ignored_transactions, day) do
    ignored_transactions_ids = Enum.map(ignored_transactions, & &1.transaction_id)

    total_spent =
      transactions
      |> Enum.filter(fn transaction ->
        transaction.transaction_id not in ignored_transactions_ids
      end)
      |> Enum.reduce(0.0, fn transaction, total_spent -> transaction.amount + total_spent end)

    {:ok,
     %{
       ignored_transactions_ids: ignored_transactions_ids,
       ignored_transactions: ignored_transactions,
       transactions: transactions || [],
       total_spent: total_spent,
       start_date: Porkybank.Utils.get_first_day_of_month(day),
       end_date: Porkybank.Utils.get_last_day_of_month(day),
       today: day
     }}
  end

  defp get_access_tokens(user) do
    user = Porkybank.Repo.preload(user, :plaid_accounts)
    Enum.map(user.plaid_accounts, & &1.access_token)
  end
end
