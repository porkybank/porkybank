defmodule Porkybank.Repo.Migrations.AddInstitutionNamePlaidAccount do
  use Ecto.Migration

  def change do
    alter table(:plaid_accounts) do
      add :institution_name, :string
      remove :account_id
    end
  end
end
