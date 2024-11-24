defmodule PorkybankWeb.Plugs.RequirePlaidAccount do
  use Phoenix.Controller

  import Plug.Conn
  import Ecto.Query
  alias Porkybank.Repo
  alias Porkybank.Banking.PlaidAccount

  def init(default), do: default

  def call(conn, _default) do
    user_id = conn.assigns[:current_user].id

    case Repo.one(
           from pa in PlaidAccount,
             where: pa.user_id == ^user_id,
             select: count(pa.id)
         ) do
      0 ->
        if conn.assigns[:current_user].opted_out_of_plaid_at do
          conn
        else
          conn
          |> put_flash(:error, "You must have a Plaid account.")
          |> redirect(to: "/setup/plaid")
          |> halt()
        end

      _ ->
        conn
    end
  end
end
