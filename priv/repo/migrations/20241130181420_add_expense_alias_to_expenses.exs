defmodule Porkybank.Repo.Migrations.AddExpenseAliasToExpenses do
  use Ecto.Migration

  def change do
    alter table(:expenses) do
      add :expense_alias, :string
    end
  end
end
