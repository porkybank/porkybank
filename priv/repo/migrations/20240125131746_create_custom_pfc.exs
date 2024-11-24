defmodule Porkybank.Repo.Migrations.CreateCustomPfc do
  use Ecto.Migration

  def change do
    create table(:custom_pfc, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :name, :string
      add :color, :string
      add :emoji, :string
      add :description, :string

      timestamps()
    end
  end
end
