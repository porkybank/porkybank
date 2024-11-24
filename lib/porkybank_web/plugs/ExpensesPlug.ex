defmodule PorkybankWeb.Plugs.RequireExpense do
  use Phoenix.Controller

  import Plug.Conn
  import Ecto.Query
  alias Porkybank.Repo
  alias Porkybank.Banking.Expense

  def init(default), do: default

  def call(conn, _default) do
    user_id = conn.assigns[:current_user].id

    case Repo.one(
           from e in Expense,
             where: e.user_id == ^user_id,
             select: count(e.id)
         ) do
      0 ->
        conn
        |> put_flash(:error, "You must have an expense.")
        |> redirect(to: "/setup/expense")
        |> halt()

      _ ->
        conn
    end
  end
end
