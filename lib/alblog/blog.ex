defmodule Alblog.Blog do
  @moduledoc """
  The Blog context.
  """

  import Ecto.Query, warn: false
  alias Alblog.Repo

  alias Alblog.Blog.Article
  alias Alblog.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any article changes.

  The broadcasted messages match the pattern:

    * {:created, %Article{}}
    * {:updated, %Article{}}
    * {:deleted, %Article{}}

  """
  def subscribe_articles(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Alblog.PubSub, "user:#{key}:articles")
  end

  defp broadcast_article(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Alblog.PubSub, "user:#{key}:articles", message)
  end

  @doc """
  Returns the list of articles.

  ## Examples

      iex> list_articles(scope)
      [%Article{}, ...]

  """
  def list_articles(%Scope{} = scope) do
    Repo.all_by(Article, user_id: scope.user.id)
  end

  @doc """
  Returns the list of all articles.
  """
  def list_all_articles do
    Repo.all(Article)
  end

  @doc """
  Gets a single article.

  Raises `Ecto.NoResultsError` if the Article does not exist.

  ## Examples

      iex> get_article!(scope, 123)
      %Article{}

      iex> get_article!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_article!(%Scope{} = scope, id) do
    Repo.get_by!(Article, id: id, user_id: scope.user.id)
  end

  @doc """
  Gets a single article by ID.
  """
  def get_article!(id) do
    Repo.get!(Article, id)
  end

  @doc """
  Creates a article.

  ## Examples

      iex> create_article(scope, %{field: value})
      {:ok, %Article{}}

      iex> create_article(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_article(%Scope{} = scope, attrs) do
    with {:ok, article = %Article{}} <-
           %Article{}
           |> Article.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_article(scope, {:created, article})
      {:ok, article}
    end
  end

  @doc """
  Updates a article.

  ## Examples

      iex> update_article(scope, article, %{field: new_value})
      {:ok, %Article{}}

      iex> update_article(scope, article, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_article(%Scope{} = scope, %Article{} = article, attrs) do
    true = article.user_id == scope.user.id

    with {:ok, article = %Article{}} <-
           article
           |> Article.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_article(scope, {:updated, article})
      {:ok, article}
    end
  end

  @doc """
  Deletes a article.

  ## Examples

      iex> delete_article(scope, article)
      {:ok, %Article{}}

      iex> delete_article(scope, article)
      {:error, %Ecto.Changeset{}}

  """
  def delete_article(%Scope{} = scope, %Article{} = article) do
    true = article.user_id == scope.user.id

    with {:ok, article = %Article{}} <-
           Repo.delete(article) do
      broadcast_article(scope, {:deleted, article})
      {:ok, article}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking article changes.

  ## Examples

      iex> change_article(scope, article)
      %Ecto.Changeset{data: %Article{}}

  """
  def change_article(%Scope{} = scope, %Article{} = article, attrs \\ %{}) do
    true = article.user_id == scope.user.id

    Article.changeset(article, attrs, scope)
  end
end
