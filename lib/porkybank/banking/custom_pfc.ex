defmodule Porkybank.Banking.CustomPfc do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "custom_pfc" do
    field :name, :string
    field :color, :string
    field :emoji, :string
    field :description, :string

    timestamps()
  end

  def changeset(custom_pfc, attrs) do
    custom_pfc
    |> cast(attrs, [:name, :color, :emoji, :description])
    |> validate_required([:name, :color, :emoji, :description])
  end
end
