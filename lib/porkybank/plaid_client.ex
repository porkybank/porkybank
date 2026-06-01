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

  defp webhook_url do
    endpoint = Application.get_env(:porkybank, PorkybankWeb.Endpoint)
    url_config = Keyword.get(endpoint, :url, [])
    host = Keyword.get(url_config, :host, "localhost")
    scheme = Keyword.get(url_config, :scheme, "https")
    "#{scheme}://#{host}/api/plaid/webhook"
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
        {:ok, %{status: 429}} ->
          {:error, "Try again later"}

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

    period_start = Keyword.get(opts, :period_start)

    # If the period spans a month boundary (e.g. May 30 – Jun 14), also pull
    # the prior month's transactions that fall within the period.
    prior_month_transactions =
      if period_start && Date.to_iso8601(period_start) < first_day_of_month do
        period_start_iso = Date.to_iso8601(period_start)
        prev_last_day = Date.add(Date.from_iso8601!(first_day_of_month), -1) |> Date.to_iso8601()

        Porkybank.Banking.PlaidTransaction
        |> where(user_id: ^user.id)
        |> where([t], t.date >= ^period_start_iso and t.date <= ^prev_last_day)
        |> Porkybank.Repo.all()
      else
        []
      end

    calculate_totals(transactions ++ prior_month_transactions, ignored_transactions, today, period_start)
  end

  def update_webhook(access_token) do
    post(
      "/item/webhook/update",
      Map.merge(base_request(), %{access_token: access_token, webhook: webhook_url()}),
      headers: [{"content-type", "application/json"}]
    )
  end

  def get_access_token(public_token) do
    request_body = Map.merge(base_request(), %{public_token: public_token})

    case post("/item/public_token/exchange", request_body,
           headers: [{"content-type", "application/json"}]
         ) do
      {:ok, %{body: %{"access_token" => access_token, "item_id" => item_id}}} ->
        {access_token, item_id}

      {:error, %{"error_message" => error_message}} ->
        error_message
    end
  end

  def get_item_id(access_token) do
    case post("/item/get", Map.merge(base_request(), %{access_token: access_token}),
           headers: [{"content-type", "application/json"}]
         ) do
      {:ok, %{body: %{"item" => %{"item_id" => item_id}}}} -> {:ok, item_id}
      {:ok, %{body: body}} -> {:error, body}
      {:error, reason} -> {:error, reason}
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
        webhook: webhook_url(),
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

  defp calculate_totals(transactions, ignored_transactions, day, period_start \\ nil) do
    ignored_transactions_ids = Enum.map(ignored_transactions, & &1.transaction_id)

    active_transactions =
      transactions
      |> Enum.filter(fn transaction ->
        transaction.transaction_id not in ignored_transactions_ids
      end)

    period_start_iso = period_start && Date.to_iso8601(period_start)

    total_spent =
      active_transactions
      |> Enum.filter(fn tx -> is_nil(period_start_iso) or tx.date >= period_start_iso end)
      |> Enum.reduce(0.0, fn transaction, total_spent -> transaction.amount + total_spent end)

    today_iso = Date.to_iso8601(day)

    today_spent =
      active_transactions
      |> Enum.filter(fn transaction -> transaction.date == today_iso end)
      |> Enum.reduce(0.0, fn transaction, total -> transaction.amount + total end)

    {:ok,
     %{
       ignored_transactions_ids: ignored_transactions_ids,
       ignored_transactions: ignored_transactions,
       transactions: transactions || [],
       total_spent: total_spent,
       today_spent: today_spent,
       start_date: if(period_start, do: Date.to_iso8601(period_start), else: Porkybank.Utils.get_first_day_of_month(day)),
       end_date: Porkybank.Utils.get_last_day_of_month(day),
       today: day
     }}
  end

  defp get_access_tokens(user) do
    user = Porkybank.Repo.preload(user, :plaid_accounts)
    Enum.map(user.plaid_accounts, & &1.access_token)
  end
end
