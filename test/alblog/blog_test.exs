defmodule Alblog.BlogTest do
  use Alblog.DataCase

  alias Alblog.Blog

  describe "articles" do
    alias Alblog.Blog.Article

    import Alblog.AccountsFixtures, only: [user_scope_fixture: 0]
    import Alblog.BlogFixtures

    @invalid_attrs %{title: nil, category: nil, slug: nil, content: nil, published_at: nil}

    test "list_articles/1 returns all scoped articles" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      article = article_fixture(scope)
      other_article = article_fixture(other_scope)
      assert Blog.list_articles(scope) == [article]
      assert Blog.list_articles(other_scope) == [other_article]
    end

    test "get_article!/2 returns the article with given id" do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      other_scope = user_scope_fixture()
      assert Blog.get_article!(scope, article.id) == article
      assert_raise Ecto.NoResultsError, fn -> Blog.get_article!(other_scope, article.id) end
    end

    test "create_article/2 with valid data creates a article" do
      valid_attrs = %{
        title: "some title",
        category: "some category",
        slug: "some slug",
        content: "some content",
        published_at: ~U[2025-11-16 18:24:00Z]
      }

      scope = user_scope_fixture()

      assert {:ok, %Article{} = article} = Blog.create_article(scope, valid_attrs)
      assert article.title == "some title"
      assert article.category == "some category"
      assert article.slug == "some slug"
      assert article.content == "some content"
      assert article.published_at == ~U[2025-11-16 18:24:00Z]
      assert article.user_id == scope.user.id
    end

    test "create_article/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Blog.create_article(scope, @invalid_attrs)
    end

    test "update_article/3 with valid data updates the article" do
      scope = user_scope_fixture()
      article = article_fixture(scope)

      update_attrs = %{
        title: "some updated title",
        category: "some updated category",
        slug: "some updated slug",
        content: "some updated content",
        published_at: ~U[2025-11-17 18:24:00Z]
      }

      assert {:ok, %Article{} = article} = Blog.update_article(scope, article, update_attrs)
      assert article.title == "some updated title"
      assert article.category == "some updated category"
      assert article.slug == "some updated slug"
      assert article.content == "some updated content"
      assert article.published_at == ~U[2025-11-17 18:24:00Z]
    end

    test "update_article/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      article = article_fixture(scope)

      assert_raise MatchError, fn ->
        Blog.update_article(other_scope, article, %{})
      end
    end

    test "update_article/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Blog.update_article(scope, article, @invalid_attrs)
      assert article == Blog.get_article!(scope, article.id)
    end

    test "delete_article/2 deletes the article" do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      assert {:ok, %Article{}} = Blog.delete_article(scope, article)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_article!(scope, article.id) end
    end

    test "delete_article/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      article = article_fixture(scope)
      assert_raise MatchError, fn -> Blog.delete_article(other_scope, article) end
    end

    test "change_article/2 returns a article changeset" do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      assert %Ecto.Changeset{} = Blog.change_article(scope, article)
    end
  end
end
