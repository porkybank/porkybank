defmodule Porkybank.Repo.Migrations.AddNullToCategoryAndCategoryId do
  use Ecto.Migration

  def change do
    alter table(:plaid_transactions) do
      modify :category, {:array, :string}, null: true
      modify :category_id, :string, null: true
    end
  end
end
