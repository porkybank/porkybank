defmodule Porkybank.Repo.Migrations.RemoveUniqueConstraintFromPlaidAccounts do
  use Ecto.Migration

  def change do
    drop index(:plaid_accounts, [:user_id], name: :plaid_accounts_user_id_index)
  end
end
