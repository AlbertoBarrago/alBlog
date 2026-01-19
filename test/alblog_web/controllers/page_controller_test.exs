defmodule AlblogWeb.PageControllerTest do
  use AlblogWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Debugging life one commit at a time"
  end
end
