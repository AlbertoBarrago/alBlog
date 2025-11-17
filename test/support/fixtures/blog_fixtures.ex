defmodule SimpleCrud.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SimpleCrud.Blog` context.
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
        category: "some category",
        content: "some content",
        published_at: ~U[2025-11-16 18:24:00Z],
        slug: unique_article_slug(),
        title: "some title"
      })

    {:ok, article} = SimpleCrud.Blog.create_article(scope, attrs)
    article
  end
end
