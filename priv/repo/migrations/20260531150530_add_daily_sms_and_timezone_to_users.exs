defmodule Porkybank.Repo.Migrations.AddDailySmsAndTimezoneToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :daily_sms_enabled, :boolean, default: false, null: false
      add :timezone, :string
    end
  end
end
