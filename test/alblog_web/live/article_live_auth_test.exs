defmodule AlblogWeb.ArticleLiveAuthTest do
  use AlblogWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "Index allows public access", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/articles")
    assert html =~ "Listing Articles"
  end

  test "New Article redirects non-admin users", %{conn: conn} do
    assert {:error,
            {:redirect,
             %{to: "/", flash: %{"error" => "You are not authorized to access this page."}}}} =
             live(conn, ~p"/articles/new")
  end
end
