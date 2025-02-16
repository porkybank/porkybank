defmodule Porkybank.Repo.Migrations.AddObanJobsTableAgain do
  use Ecto.Migration

  def up do
    # Use the latest version
    Oban.Migration.up(version: 11)
  end

  def down do
    # Roll back to the base version
    Oban.Migration.down(version: 1)
  end
end
