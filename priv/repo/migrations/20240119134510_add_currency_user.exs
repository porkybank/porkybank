defmodule Porkybank.Repo.Migrations.AddCurrencyUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :currency, :string, default: "USD"
    end
  end
end
