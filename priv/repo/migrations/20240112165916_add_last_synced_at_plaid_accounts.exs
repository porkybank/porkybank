defmodule Porkybank.Repo.Migrations.AddLastSyncedAtPlaidAccounts do
  use Ecto.Migration

  def change do
    alter table(:plaid_accounts) do
      add :last_synced_at, :naive_datetime
    end
  end
end
