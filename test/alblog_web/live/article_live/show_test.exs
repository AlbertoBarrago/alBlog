defmodule AlblogWeb.ArticleLive.ShowTest do
  use AlblogWeb.ConnCase

  import Phoenix.LiveViewTest
  import Alblog.BlogFixtures
  import Alblog.AccountsFixtures

  @create_attrs %{
    title: "Test Article",
    category: ["test category"],
    content: "Test content for article",
    published_at: "2025-11-21T18:24:00Z"
  }

  describe "Show page as admin" do
    setup %{conn: conn} do
      user = admin_fixture()
      scope = Alblog.Accounts.Scope.for_user(user)
      conn = log_in_user(conn, user)
      article = article_fixture(scope, @create_attrs)
      %{conn: conn, user: user, scope: scope, article: article}
    end

    test "displays article with edit and delete buttons", %{conn: conn, article: article} do
      {:ok, _show_live, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ article.title
      assert html =~ article.content
      # Admin should see edit button
      assert html =~ "Edit"
      # Admin should see delete button
      assert html =~ "Delete"
    end

    test "deletes article and redirects to index", %{conn: conn, article: article} do
      {:ok, show_live, _html} = live(conn, ~p"/articles/#{article}")

      # Click delete button
      assert {:ok, index_live, html} =
               show_live
               |> element("button", "Delete")
               |> render_click()
               |> follow_redirect(conn, ~p"/articles")

      # Verify redirect to articles index
      assert html =~ "Article deleted successfully"
      # Verify article is no longer in the list
      refute render(index_live) =~ article.title
    end
  end

  describe "Show page as regular user" do
    setup %{conn: conn} do
      # Create admin user to own the article
      admin_user = admin_fixture()
      admin_scope = Alblog.Accounts.Scope.for_user(admin_user)
      article = article_fixture(admin_scope, @create_attrs)

      # Create regular user to view the article
      regular_user = user_fixture()
      conn = log_in_user(conn, regular_user)

      %{conn: conn, article: article, regular_user: regular_user}
    end

    test "displays article without edit and delete buttons", %{conn: conn, article: article} do
      {:ok, _show_live, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ article.title
      assert html =~ article.content
      # Regular user should NOT see edit button
      refute html =~ "Edit"
      # Regular user should NOT see delete button
      refute html =~ "Delete"
    end
  end

  describe "Show page as guest (not logged in)" do
    setup do
      # Create admin user to own the article
      admin_user = admin_fixture()
      admin_scope = Alblog.Accounts.Scope.for_user(admin_user)
      article = article_fixture(admin_scope, @create_attrs)

      %{article: article}
    end

    test "displays article without edit and delete buttons", %{conn: conn, article: article} do
      {:ok, _show_live, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ article.title
      assert html =~ article.content
      # Guest should NOT see edit button
      refute html =~ "Edit"
      # Guest should NOT see delete button
      refute html =~ "Delete"
    end
  end
end
