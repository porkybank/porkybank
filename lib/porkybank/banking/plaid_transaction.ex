defmodule Porkybank.Banking.PlaidTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plaid_transactions" do
    field :account_id, :string
    field :account_owner, :string
    field :amount, :float
    field :authorized_date, :string
    field :authorized_datetime, :string
    field :category, {:array, :string}
    field :category_id, :string
    field :check_number, :string
    field :counterparties, {:array, :map}
    field :date, :string
    field :datetime, :string
    field :iso_currency_code, :string
    field :location, :map
    field :logo_url, :string
    field :merchant_entity_id, :string
    field :merchant_name, :string
    field :name, :string
    field :payment_channel, :string
    field :payment_meta, :map
    field :pending, :boolean
    field :pending_transaction_id, :string
    field :personal_finance_category, :map
    field :personal_finance_category_icon_url, :string
    field :transaction_code, :string
    field :transaction_id, :string
    field :transaction_type, :string
    field :unofficial_currency_code, :string
    field :website, :string
    field :is_manual, :boolean, default: false
    belongs_to :user, Porkybank.Accounts.User, type: :integer

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :account_id,
      :account_owner,
      :amount,
      :authorized_date,
      :authorized_datetime,
      :category,
      :category_id,
      :check_number,
      :counterparties,
      :date,
      :datetime,
      :iso_currency_code,
      :location,
      :logo_url,
      :merchant_entity_id,
      :merchant_name,
      :name,
      :payment_channel,
      :payment_meta,
      :pending,
      :pending_transaction_id,
      :personal_finance_category,
      :personal_finance_category_icon_url,
      :transaction_code,
      :transaction_id,
      :transaction_type,
      :unofficial_currency_code,
      :website
    ])
    |> validate_required([
      :account_id,
      :amount,
      :counterparties,
      :date,
      :iso_currency_code,
      :name,
      :payment_channel,
      :payment_meta,
      :pending,
      :personal_finance_category,
      :personal_finance_category_icon_url,
      :transaction_id,
      :transaction_type
    ])
  end

  def manual_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :amount,
      :date,
      :name,
      :personal_finance_category
    ])
    |> validate_required([
      :amount,
      :date,
      :name
    ])
  end
end

# %{
#   "account_id" => "OxvavoqxO7fA6K6K5nBphAqgmRmO86FgYngA7",
#   "account_owner" => nil,
#   "amount" => 25.47,
#   "authorized_date" => "2024-01-05",
#   "authorized_datetime" => "2024-01-05T00:00:00Z",
#   "category" => ["Food and Drink", "Restaurants"],
#   "category_id" => "13005000",
#   "check_number" => nil,
#   "counterparties" => [
#     %{
#       "confidence_level" => "LOW",
#       "entity_id" => nil,
#       "logo_url" => nil,
#       "name" => "Navalcarnero",
#       "phone_number" => nil,
#       "type" => "merchant",
#       "website" => nil
#     }
#   ],
#   "date" => "2024-01-07",
#   "datetime" => "2024-01-07T16:08:28Z",
#   "iso_currency_code" => "USD",
#   "location" => %{
#     "address" => nil,
#     "city" => nil,
#     "country" => nil,
#     "lat" => nil,
#     "lon" => nil,
#     "postal_code" => nil,
#     "region" => nil,
#     "store_number" => nil
#   },
#   "logo_url" => nil,
#   "merchant_entity_id" => nil,
#   "merchant_name" => "Navalcarnero",
#   "name" => "BK 19726. NAVALCARNERO",
#   "payment_channel" => "in store",
#   "payment_meta" => %{
#     "by_order_of" => nil,
#     "payee" => nil,
#     "payer" => nil,
#     "payment_method" => nil,
#     "payment_processor" => nil,
#     "ppd_id" => nil,
#     "reason" => nil,
#     "reference_number" => nil
#   },
#   "pending" => false,
#   "pending_transaction_id" => "vMKYK3aMVZT1b4b4BkxaUnqxZjdv5aF00ogeA",
#   "personal_finance_category" => %{
#     "confidence_level" => "LOW",
#     "detailed" => "TRANSPORTATION_GAS",
#     "primary" => "TRANSPORTATION"
#   },
#   "personal_finance_category_icon_url" => "https://plaid-category-icons.plaid.com/PFC_TRANSPORTATION.png",
#   "transaction_code" => nil,
#   "transaction_id" => "kEdBdXKEboH6xJxJbk3nipLgZ7kqq7tZwzAORb",
#   "transaction_type" => "place",
#   "unofficial_currency_code" => nil,
#   "website" => nil
# }
