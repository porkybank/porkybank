defmodule Porkybank.Repo.Migrations.CreatePlaidTransactions do
  use Ecto.Migration

  def change do
    create table(:plaid_transactions) do
      add :account_id, :string
      add :account_owner, :string
      add :amount, :float
      add :authorized_date, :string
      add :authorized_datetime, :string
      add :category, {:array, :string}
      add :category_id, :string
      add :check_number, :string
      add :counterparties, {:array, :map}
      add :date, :string
      add :datetime, :string
      add :iso_currency_code, :string
      add :location, :map
      add :logo_url, :string
      add :merchant_entity_id, :string
      add :merchant_name, :string
      add :name, :string
      add :payment_channel, :string
      add :payment_meta, :map
      add :pending, :boolean
      add :pending_transaction_id, :string
      add :personal_finance_category, :map
      add :personal_finance_category_icon_url, :string
      add :transaction_code, :string
      add :transaction_id, :string
      add :transaction_type, :string
      add :unofficial_currency_code, :string
      add :website, :string
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:plaid_transactions, [:user_id])
  end
end
