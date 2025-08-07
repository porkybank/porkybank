defmodule Porkybank.Repo.Migrations.AddUniqueTransactionId do
  use Ecto.Migration

  def change do
    create unique_index(:plaid_transactions, [:transaction_id])
  end
end
