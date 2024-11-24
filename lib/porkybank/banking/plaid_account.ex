defmodule Porkybank.Banking.PlaidAccount do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plaid_accounts" do
    field :institution_name, :string
    field :access_token, :string
    field :account_id, :string
    field :last_synced_at, :naive_datetime
    belongs_to :user, Porkybank.Accounts.User, type: :integer

    timestamps()
  end

  def changeset(plaid_account, attrs) do
    plaid_account
    |> cast(attrs, [:access_token, :institution_name, :account_id, :last_synced_at])
    |> validate_required([:access_token, :institution_name, :account_id])
  end
end
