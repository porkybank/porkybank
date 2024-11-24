defmodule Porkybank.Banking.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "expenses" do
    field :amount, :decimal
    field :description, :string
    field :date, :date
    field :recurring, :boolean, default: true
    field :recurring_period, :string, default: "monthly"

    belongs_to :category, Porkybank.Banking.Category
    belongs_to :user, Porkybank.Accounts.User, type: :integer

    timestamps()
  end

  @doc false
  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [:amount, :description, :date, :recurring, :recurring_period, :category_id])
    |> validate_required([
      :amount,
      :description,
      :date,
      :recurring,
      :recurring_period
    ])
  end
end
