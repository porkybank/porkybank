defmodule Porkybank.Repo.Migrations.AddAccountIdPlaidAccounts do
  use Ecto.Migration

  def change do
    alter table(:plaid_accounts) do
      add :account_id, :string
    end
  end
end
