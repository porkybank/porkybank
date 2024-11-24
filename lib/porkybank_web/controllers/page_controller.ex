defmodule PorkybankWeb.PageController do
  use PorkybankWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.

    conn
    |> redirect(to: "/overview")
  end
end
