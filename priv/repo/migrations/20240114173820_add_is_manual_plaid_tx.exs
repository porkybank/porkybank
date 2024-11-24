defmodule Porkybank.Repo.Migrations.AddIsManualPlaidTx do
  use Ecto.Migration

  def change do
    alter table(:plaid_transactions) do
      add :is_manual, :boolean, default: false
    end
  end
end
