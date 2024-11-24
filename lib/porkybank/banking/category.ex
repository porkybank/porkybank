defmodule Porkybank.Banking.Category do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Porkybank.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "categories" do
    field :name, :string
    field :color, :string
    field :emoji, :string, default: nil
    field :description, :string

    belongs_to :user, Porkybank.Accounts.User, type: :integer

    timestamps()
  end

  @doc false
  def changeset(category, attrs, user_id) do
    category
    |> cast(attrs, [:name, :description, :color, :emoji])
    |> validate_required([:name])
    |> validate_unique(:name, user_id)
  end

  def validate_unique(changeset, field, user_id) do
    custom_pfcs = Repo.all(Porkybank.Banking.CustomPfc)

    categories =
      Repo.all(
        from c in Porkybank.Banking.Category,
          where: c.user_id == ^user_id or is_nil(c.user_id)
      )

    categories = custom_pfcs ++ categories

    field_value = get_field(changeset, field)

    if Enum.any?(categories, &(&1.name == field_value || &1.description == field_value)) do
      add_error(changeset, field, "has already been taken")
    else
      changeset
    end
  end
end
