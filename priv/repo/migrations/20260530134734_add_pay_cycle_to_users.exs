defmodule Porkybank.Repo.Migrations.AddPayCycleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pay_cycle, :string
    end
  end
end
