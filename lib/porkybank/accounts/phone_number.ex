defmodule Porkybank.Accounts.PhoneNumber do
  use Ecto.Schema
  import Ecto.Changeset

  schema "phone_numbers" do
    field :number, :string
    belongs_to :user, Porkybank.Accounts.User, type: :integer

    timestamps()
  end

  def changeset(phone_number, attrs) do
    phone_number
    |> cast(attrs, [:number])
    |> validate_required([:number])
    |> validate_format(:number, ~r/^\+[1-9]\d{1,14}$/, message: "must be in E.164 format e.g. +12125551234")
    |> unique_constraint([:number, :user_id])
  end
end
