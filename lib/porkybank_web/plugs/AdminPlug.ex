defmodule PorkybankWeb.Plugs.RequireAdmin do
  use Phoenix.Controller

  def init(default), do: default

  def call(conn, _opts) do
    if PorkybankWeb.UserAuth.is_admin?(conn.assigns[:current_user]) do
      conn
    else
      conn
      |> put_flash(:error, "You must be an admin to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
