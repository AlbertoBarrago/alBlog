defmodule SimpleCrudWeb.ArticleLive.ShowPublicTest do
  use SimpleCrudWeb.ConnCase

  import Phoenix.LiveViewTest
  import SimpleCrud.BlogFixtures

  @create_attrs %{
    title: "some title",
    category: "some category",
    slug: "some slug",
    content: "some content",
    published_at: "2025-11-16T18:24:00Z"
  }

  setup :register_and_log_in_user

  defp create_article(%{scope: scope}) do
    article = article_fixture(scope, @create_attrs)
    %{article: article}
  end

  describe "Public Article Show" do
    setup [:create_article]

    test "displays article and presence count", %{conn: conn, article: article} do
      {:ok, show_live, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ article.title
      assert html =~ article.content

      # Check for presence indicator
      assert html =~ "reading now"
      assert render(show_live) =~ "1 reading now"
    end
  end
end
