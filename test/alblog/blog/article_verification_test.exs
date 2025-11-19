defmodule Alblog.Blog.ArticleVerificationTest do
  use Alblog.DataCase

  alias Alblog.Blog.Article

  describe "article features" do
    test "changeset generates slug from title" do
      attrs = %{title: "Hello World! This is a Test", content: "Content"}
      # Mock user scope
      user_scope = %{user: %{id: 1}}

      changeset = Article.changeset(%Article{}, attrs, user_scope)

      assert get_change(changeset, :slug) == "hello-world-this-is-a-test"
    end

    test "changeset sets default published_at if missing" do
      attrs = %{title: "Title", content: "Content"}
      user_scope = %{user: %{id: 1}}

      changeset = Article.changeset(%Article{}, attrs, user_scope)

      assert get_change(changeset, :published_at) != nil
    end

    test "changeset accepts category as list of strings" do
      attrs = %{title: "Title", content: "Content", category: ["tech", "elixir"]}
      user_scope = %{user: %{id: 1}}

      changeset = Article.changeset(%Article{}, attrs, user_scope)

      assert get_change(changeset, :category) == ["tech", "elixir"]
    end
  end
end
