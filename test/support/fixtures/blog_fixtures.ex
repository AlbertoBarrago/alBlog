defmodule Alblog.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Alblog.Blog` context.
  """

  @doc """
  Generate a unique article slug.
  """
  def unique_article_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a article.
  """
  def article_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        category: ["some category"],
        content: "some content",
        published_at: ~U[2025-11-16 18:24:00Z],
        slug: unique_article_slug(),
        title: "some title#{System.unique_integer([:positive])}"
      })

    {:ok, article} = Alblog.Blog.create_article(scope, attrs)
    Alblog.Repo.preload(article, :user)
  end

  @doc """
  Generate a comment.
  """
  def comment_fixture(scope, article, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        body: "This is a test comment #{System.unique_integer([:positive])}"
      })

    {:ok, comment} = Alblog.Blog.create_comment(scope, article, attrs)
    comment
  end

  @doc """
  Generate article visit records for testing.
  """
  def article_visit_fixture(article, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        date: Date.utc_today(),
        visit_count: 1
      })

    {:ok, visit} =
      %Alblog.Blog.ArticleVisit{article_id: article.id}
      |> Alblog.Blog.ArticleVisit.changeset(attrs)
      |> Alblog.Repo.insert()

    visit
  end
end
