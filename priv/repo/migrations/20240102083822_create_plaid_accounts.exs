defmodule Porkybank.Repo.Migrations.CreatePlaidAccounts do
  use Ecto.Migration

  def change do
    create table(:plaid_accounts) do
      add :access_token, :string
      add :user_id, references(:users, type: :bigserial)

      timestamps()
    end

    create unique_index(:plaid_accounts, [:user_id])
  end
end
