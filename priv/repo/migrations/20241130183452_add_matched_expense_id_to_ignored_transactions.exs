defmodule Porkybank.Repo.Migrations.AddMatchedExpenseIdToIgnoredTransactions do
  use Ecto.Migration

  def change do
    alter table(:ignored_transactions) do
      add :matched_expense_id, :binary_id
    end
  end
end
