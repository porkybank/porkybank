defmodule Mix.Tasks.Plaid.RegisterWebhooks do
  use Mix.Task

  @shortdoc "Register the Plaid webhook URL for all existing accounts and backfill item_id"

  def run(_args) do
    Application.ensure_all_started(:porkybank)

    accounts = Porkybank.Repo.all(Porkybank.Banking.PlaidAccount)

    IO.puts("Updating #{length(accounts)} account(s)...")

    Enum.each(accounts, fn account ->
      with {:ok, _} <- Porkybank.PlaidClient.update_webhook(account.access_token),
           {:ok, item_id} <- Porkybank.PlaidClient.get_item_id(account.access_token) do
        account
        |> Ecto.Changeset.change(item_id: item_id)
        |> Porkybank.Repo.update!()
        IO.puts("  [ok] account_id=#{account.account_id} institution=#{account.institution_name} item_id=#{item_id}")
      else
        {:error, reason} ->
          IO.puts("  [fail] account_id=#{account.account_id} reason=#{inspect(reason)}")
      end
    end)
  end
end
