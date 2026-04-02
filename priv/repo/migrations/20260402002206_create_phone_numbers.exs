defmodule Porkybank.Repo.Migrations.CreatePhoneNumbers do
  use Ecto.Migration

  def change do
    create table(:phone_numbers) do
      add :number, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:phone_numbers, [:user_id])
    create unique_index(:phone_numbers, [:number, :user_id])
  end
end
