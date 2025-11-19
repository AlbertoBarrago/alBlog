defmodule AlblogWeb.ArticleLiveTest do
  use AlblogWeb.ConnCase

  import Phoenix.LiveViewTest
  import Alblog.BlogFixtures

  @invalid_attrs %{title: nil, content: nil}

  setup :register_and_log_in_user

  defp create_article(%{scope: scope}) do
    article = article_fixture(scope)

    %{article: article}
  end

  describe "Index" do
    setup [:create_article]

    test "lists all articles", %{conn: conn, article: article} do
      {:ok, _index_live, html} = live(conn, ~p"/articles")

      assert html =~ "Listing Articles"
      assert html =~ article.title
    end

    test "saves new article", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/articles")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Article")
               |> render_click()
               |> follow_redirect(conn, ~p"/articles/new")

      assert render(form_live) =~ "New Article"

      assert form_live
             |> form("#article-form", article: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      _ =
        form_live
        |> element("input[name=tag_input]")
        |> render_keydown(%{"key" => "Enter", "value" => "some category"})

      assert {:ok, index_live, _html} =
               form_live
               |> form("#article-form", article: %{title: "some title", content: "some content"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/articles")

      html = render(index_live)
      assert html =~ "Article created successfully"
      assert html =~ "some title"
    end

    test "updates article in listing", %{conn: conn, article: article} do
      {:ok, index_live, _html} = live(conn, ~p"/articles")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#articles-#{article.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/articles/#{article}/edit")

      assert render(form_live) =~ "Edit Article"

      assert form_live
             |> form("#article-form", article: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      _ =
        form_live
        |> element("input[name=tag_input]")
        |> render_keydown(%{"key" => "Enter", "value" => "some updated category"})

      assert {:ok, index_live, _html} =
               form_live
               |> form("#article-form",
                 article: %{title: "some updated title", content: "some updated content"}
               )
               |> render_submit()
               |> follow_redirect(conn, ~p"/articles")

      html = render(index_live)
      assert html =~ "Article updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes article in listing", %{conn: conn, article: article} do
      {:ok, index_live, _html} = live(conn, ~p"/articles")

      assert index_live |> element("#articles-#{article.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#articles-#{article.id}")
    end
  end

  # Show tests removed as Show is now a controller action
end
