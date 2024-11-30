defmodule Porkybank.Banking.IgnoredTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ignored_transactions" do
    field :transaction_id, :string
    field :reason, :string
    field :matched_expense_id, :binary_id

    belongs_to :user, Porkybank.Accounts.User, type: :integer

    timestamps()
  end

  @doc false
  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [:transaction_id, :reason, :matched_expense_id])
    |> validate_required([
      :transaction_id,
      :reason
    ])
  end
end
