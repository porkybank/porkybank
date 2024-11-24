defmodule PorkybankWeb.Plugs.RequireIncome do
  use Phoenix.Controller

  import Plug.Conn
  import Ecto.Query
  alias Porkybank.Repo
  alias Porkybank.Banking.Income

  def init(default), do: default

  def call(conn, _default) do
    user_id = conn.assigns[:current_user].id

    case Repo.one(
           from i in Income,
             where: i.user_id == ^user_id,
             select: count(i.id)
         ) do
      0 ->
        conn
        |> put_flash(:error, "You must have an income.")
        |> redirect(to: "/setup/income")
        |> halt()

      _ ->
        conn
    end
  end
end
