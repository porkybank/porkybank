defmodule Porkybank.Repo.Migrations.CreateExpenses do
  use Ecto.Migration

  def change do
    create table(:expenses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount, :decimal
      add :description, :string
      add :date, :date
      add :recurring, :boolean, default: false
      add :recurring_period, :string, default: "monthly"

      add :category_id, references(:categories, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
  end
end
