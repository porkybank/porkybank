defmodule Porkybank.Repo.Migrations.AddItemIdToPlaidAccounts do
  use Ecto.Migration

  def change do
    alter table(:plaid_accounts) do
      add :item_id, :string
    end
  end
end
