defmodule Porkybank.Repo.Migrations.AddOptedOutOfPlaidAtUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :opted_out_of_plaid_at, :naive_datetime
    end
  end
end
