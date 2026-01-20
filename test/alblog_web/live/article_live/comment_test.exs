defmodule AlblogWeb.ArticleLive.CommentTest do
  use AlblogWeb.ConnCase

  import Phoenix.LiveViewTest
  import Alblog.AccountsFixtures
  import Alblog.BlogFixtures

  describe "Comments on article show page (logged in user)" do
    setup :register_and_log_in_user

    setup %{scope: scope} do
      article = article_fixture(scope)
      %{article: article}
    end

    test "shows comment form for logged in users", %{conn: conn, article: article} do
      {:ok, _view, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ "comment-form"
      assert html =~ "Write a comment"
      assert html =~ "Post Comment"
    end

    test "shows empty state when no comments", %{conn: conn, article: article} do
      {:ok, _view, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ "No comments yet"
    end

    test "can create a comment", %{conn: conn, article: article} do
      {:ok, view, _html} = live(conn, ~p"/articles/#{article}")

      assert view
             |> form("#comment-form", comment: %{body: "This is a great article!"})
             |> render_submit() =~ "Comment added successfully"

      assert render(view) =~ "This is a great article!"
      # The comment should be visible
      assert has_element?(view, "#comments div", "This is a great article!")
    end

    test "validates comment body", %{conn: conn, article: article} do
      {:ok, view, _html} = live(conn, ~p"/articles/#{article}")

      assert view
             |> form("#comment-form", comment: %{body: ""})
             |> render_change() =~ "can&#39;t be blank"
    end

    test "validates comment max length", %{conn: conn, article: article} do
      {:ok, view, _html} = live(conn, ~p"/articles/#{article}")

      long_body = String.duplicate("a", 2001)

      assert view
             |> form("#comment-form", comment: %{body: long_body})
             |> render_change() =~ "should be at most 2000 character(s)"
    end

    test "shows existing comments", %{conn: conn, article: article, scope: scope} do
      _comment = comment_fixture(scope, article, %{body: "Existing comment here"})

      {:ok, _view, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ "Existing comment here"
    end

    test "can delete own comment", %{conn: conn, article: article, scope: scope} do
      comment = comment_fixture(scope, article, %{body: "My comment to delete"})

      {:ok, view, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ "My comment to delete"

      assert view
             |> element("button[phx-click='delete_comment'][phx-value-id='#{comment.id}']")
             |> render_click() =~ "Comment deleted"

      refute render(view) =~ "My comment to delete"
    end

    test "cannot delete other user's comment", %{conn: conn, article: article} do
      other_scope = user_scope_fixture()
      comment = comment_fixture(other_scope, article, %{body: "Other user comment"})

      {:ok, view, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ "Other user comment"
      # Should not see delete button for other user's comment
      refute has_element?(
               view,
               "button[phx-click='delete_comment'][phx-value-id='#{comment.id}']"
             )
    end

    test "receives real-time comment updates", %{conn: conn, article: article, scope: scope} do
      {:ok, view, html} = live(conn, ~p"/articles/#{article}")

      refute html =~ "New real-time comment"

      # Simulate another user creating a comment via the context
      {:ok, _comment} =
        Alblog.Blog.create_comment(scope, article, %{body: "New real-time comment"})

      # Wait for PubSub message
      assert render(view) =~ "New real-time comment"
    end
  end

  describe "Comments on article show page (admin)" do
    setup do
      admin = admin_fixture()
      admin_scope = Alblog.Accounts.Scope.for_user(admin)
      user_scope = user_scope_fixture()
      article = article_fixture(admin_scope)

      %{admin: admin, admin_scope: admin_scope, user_scope: user_scope, article: article}
    end

    test "admin can delete any user's comment", %{
      admin: admin,
      user_scope: user_scope,
      article: article
    } do
      comment = comment_fixture(user_scope, article, %{body: "User comment for admin to delete"})

      conn = build_conn() |> log_in_user(admin)
      {:ok, view, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ "User comment for admin to delete"

      assert has_element?(
               view,
               "button[phx-click='delete_comment'][phx-value-id='#{comment.id}']"
             )

      assert view
             |> element("button[phx-click='delete_comment'][phx-value-id='#{comment.id}']")
             |> render_click() =~ "Comment deleted"

      refute render(view) =~ "User comment for admin to delete"
    end
  end

  describe "Comments on article show page (anonymous user)" do
    setup do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      %{article: article, scope: scope}
    end

    test "shows login prompt instead of comment form", %{conn: conn, article: article} do
      {:ok, _view, html} = live(conn, ~p"/articles/#{article}")

      refute html =~ "comment-form"
      assert html =~ "Log in"
      assert html =~ "to join the discussion"
    end

    test "can view existing comments", %{conn: conn, article: article, scope: scope} do
      _comment = comment_fixture(scope, article, %{body: "Public visible comment"})

      {:ok, _view, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ "Public visible comment"
    end

    test "cannot see delete buttons", %{conn: conn, article: article, scope: scope} do
      comment = comment_fixture(scope, article, %{body: "A comment"})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article}")

      refute has_element?(
               view,
               "button[phx-click='delete_comment'][phx-value-id='#{comment.id}']"
             )
    end
  end
end
