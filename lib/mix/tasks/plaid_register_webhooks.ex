defmodule Mix.Tasks.Plaid.RegisterWebhooks do
  use Mix.Task

  @shortdoc "Register the Plaid webhook URL for all existing accounts"

  def run(_args) do
    Application.ensure_all_started(:porkybank)

    accounts = Porkybank.Repo.all(Porkybank.Banking.PlaidAccount)

    Mix.shell().info("Updating #{length(accounts)} account(s)...")

    Enum.each(accounts, fn account ->
      case Porkybank.PlaidClient.update_webhook(account.access_token) do
        {:ok, %{status: 200}} ->
          Mix.shell().info("  [ok] account_id=#{account.account_id} institution=#{account.institution_name}")

        {:ok, %{status: status, body: body}} ->
          Mix.shell().error("  [fail] account_id=#{account.account_id} status=#{status} body=#{inspect(body)}")

        {:error, reason} ->
          Mix.shell().error("  [error] account_id=#{account.account_id} reason=#{inspect(reason)}")
      end
    end)
  end
end
