defmodule Porkybank.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :color, :string
      add :emoji, :string

      timestamps()
    end
  end
end
