defmodule Porkybank.Repo.Migrations.AddCompletedSetupAtUserTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :completed_setup_at, :naive_datetime, null: true
    end
  end
end
