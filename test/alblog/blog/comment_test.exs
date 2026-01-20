defmodule Alblog.Blog.CommentTest do
  use Alblog.DataCase

  alias Alblog.Blog
  alias Alblog.Blog.Comment

  import Alblog.AccountsFixtures
  import Alblog.BlogFixtures

  describe "comments" do
    setup do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      %{scope: scope, article: article}
    end

    test "list_comments/1 returns all comments for an article", %{scope: scope, article: article} do
      comment = comment_fixture(scope, article)
      [result] = Blog.list_comments(article.id)
      assert result.id == comment.id
      assert result.body == comment.body
      assert result.user_id == comment.user_id
    end

    test "list_comments/1 returns comments ordered by inserted_at", %{
      scope: scope,
      article: article
    } do
      comment1 = comment_fixture(scope, article, %{body: "First comment"})
      comment2 = comment_fixture(scope, article, %{body: "Second comment"})
      comment3 = comment_fixture(scope, article, %{body: "Third comment"})

      comments = Blog.list_comments(article.id)
      assert Enum.map(comments, & &1.id) == [comment1.id, comment2.id, comment3.id]
    end

    test "list_comments/1 does not return comments from other articles", %{
      scope: scope,
      article: article
    } do
      other_article = article_fixture(scope, %{title: "Other article"})
      _other_comment = comment_fixture(scope, other_article, %{body: "Other comment"})
      comment = comment_fixture(scope, article, %{body: "My comment"})

      [result] = Blog.list_comments(article.id)
      assert result.id == comment.id
      assert result.body == "My comment"
    end

    test "get_comment!/1 returns the comment with given id", %{scope: scope, article: article} do
      comment = comment_fixture(scope, article)
      result = Blog.get_comment!(comment.id)
      assert result.id == comment.id
      assert result.body == comment.body
      assert result.user_id == comment.user_id
    end

    test "get_comment!/1 raises for non-existent comment" do
      assert_raise Ecto.NoResultsError, fn -> Blog.get_comment!(-1) end
    end

    test "create_comment/3 with valid data creates a comment", %{scope: scope, article: article} do
      valid_attrs = %{body: "This is a great article!"}

      assert {:ok, %Comment{} = comment} = Blog.create_comment(scope, article, valid_attrs)
      assert comment.body == "This is a great article!"
      assert comment.user_id == scope.user.id
      assert comment.article_id == article.id
    end

    test "create_comment/3 with invalid data returns error changeset", %{
      scope: scope,
      article: article
    } do
      invalid_attrs = %{body: nil}
      assert {:error, %Ecto.Changeset{}} = Blog.create_comment(scope, article, invalid_attrs)
    end

    test "create_comment/3 with empty body returns error changeset", %{
      scope: scope,
      article: article
    } do
      invalid_attrs = %{body: ""}
      assert {:error, %Ecto.Changeset{}} = Blog.create_comment(scope, article, invalid_attrs)
    end

    test "create_comment/3 with body too long returns error changeset", %{
      scope: scope,
      article: article
    } do
      long_body = String.duplicate("a", 2001)
      invalid_attrs = %{body: long_body}
      assert {:error, %Ecto.Changeset{}} = Blog.create_comment(scope, article, invalid_attrs)
    end

    test "delete_comment/2 deletes the comment as owner", %{scope: scope, article: article} do
      comment = comment_fixture(scope, article)
      assert {:ok, %Comment{}} = Blog.delete_comment(scope, comment)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_comment!(comment.id) end
    end

    test "delete_comment/2 allows admin to delete any comment", %{article: article} do
      user_scope = user_scope_fixture()
      admin_scope = admin_scope_fixture()
      comment = comment_fixture(user_scope, article)

      assert {:ok, %Comment{}} = Blog.delete_comment(admin_scope, comment)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_comment!(comment.id) end
    end

    test "delete_comment/2 rejects deletion by non-owner non-admin", %{article: article} do
      user_scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      comment = comment_fixture(user_scope, article)

      assert {:error, :unauthorized} = Blog.delete_comment(other_scope, comment)
      result = Blog.get_comment!(comment.id)
      assert result.id == comment.id
      assert result.body == comment.body
    end

    test "change_comment/2 returns a comment changeset", %{scope: scope, article: article} do
      comment = comment_fixture(scope, article)
      assert %Ecto.Changeset{} = Blog.change_comment(comment)
    end
  end
end
