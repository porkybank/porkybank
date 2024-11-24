defmodule Porkybank.Repo.Migrations.CreateIncomes do
  use Ecto.Migration

  def change do
    create table(:incomes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount, :decimal
      add :recurring_period, :string, default: "monthly"

      timestamps()
    end
  end
end
