defmodule PorkybankWeb.PageControllerTest do
  use PorkybankWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/overview")
    assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
  end
end
