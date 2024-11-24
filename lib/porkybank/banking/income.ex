defmodule Porkybank.Banking.Income do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "incomes" do
    field :amount, :decimal
    field :recurring_period, :string, default: "monthly"

    belongs_to :user, Porkybank.Accounts.User, type: :integer

    timestamps()
  end

  @doc false
  def changeset(income, attrs) do
    income
    |> cast(attrs, [:amount, :recurring_period])
    |> validate_required([
      :amount,
      :recurring_period
    ])
  end
end
