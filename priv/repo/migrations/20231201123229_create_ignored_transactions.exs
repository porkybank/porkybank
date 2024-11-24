defmodule Porkybank.Repo.Migrations.CreateIgnoredTransactions do
  use Ecto.Migration

  def change do
    create table(:ignored_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :transaction_id, :string, null: false
      add :reason, :string
      timestamps()
    end
  end
end
