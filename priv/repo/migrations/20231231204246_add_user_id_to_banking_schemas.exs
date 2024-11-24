defmodule Porkybank.Repo.Migrations.AddUserIdToBankingSchemas do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :user_id, references(:users, type: :bigserial)
    end

    alter table(:ignored_transactions) do
      add :user_id, references(:users, type: :bigserial)
    end

    alter table(:expenses) do
      add :user_id, references(:users, type: :bigserial)
    end

    alter table(:incomes) do
      add :user_id, references(:users, type: :bigserial)
    end
  end
end
