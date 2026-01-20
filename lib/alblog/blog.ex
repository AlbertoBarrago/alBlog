defmodule Alblog.Blog do
  @moduledoc """
  The Blog context.
  """

  import Ecto.Query, warn: false
  alias Alblog.Repo

  alias Alblog.Blog.Article
  alias Alblog.Blog.ArticleVisit
  alias Alblog.Blog.BlogNotifier
  alias Alblog.Blog.Comment
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
  Returns the list of articles, optionally filtered by tag.

  ## Examples

      iex> list_articles(scope)
      [%Article{}, ...]

      iex> list_articles(scope, "elixir")
      [%Article{}, ...]

  """
  def list_articles(%Scope{} = scope, tag \\ nil) do
    Article
    |> where(user_id: ^scope.user.id)
    |> filter_by_tag(tag)
    |> order_by([a], desc: a.published_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Returns the list of all articles, optionally filtered by tag.
  """
  def list_all_articles(tag \\ nil) do
    Article
    |> filter_by_tag(tag)
    |> order_by([a], desc: a.published_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  defp filter_by_tag(query, nil), do: query

  defp filter_by_tag(query, tag) do
    from a in query, where: ^tag in a.category
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
    Article
    |> Repo.get_by!(id: id, user_id: scope.user.id)
    |> Repo.preload(:user)
  end

  @doc """
  Gets a single article by ID.
  """
  def get_article!(id) do
    Article
    |> Repo.get!(id)
    |> Repo.preload(:user)
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

  # Comments

  @doc """
  Subscribes to comment notifications for a specific article.

  The broadcasted messages match the pattern:

    * {:comment_created, %Comment{}}
    * {:comment_deleted, %Comment{}}

  """
  def subscribe_comments(article_id) do
    Phoenix.PubSub.subscribe(Alblog.PubSub, "article:#{article_id}:comments")
  end

  defp broadcast_comment(article_id, message) do
    Phoenix.PubSub.broadcast(Alblog.PubSub, "article:#{article_id}:comments", message)
  end

  @doc """
  Returns the list of comments for an article.

  ## Examples

      iex> list_comments(article_id)
      [%Comment{}, ...]

  """
  def list_comments(article_id) do
    Comment
    |> where(article_id: ^article_id)
    |> order_by([c], asc: c.inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id) do
    Comment
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a comment for an article.

  ## Examples

      iex> create_comment(scope, article, %{body: "Nice post!"})
      {:ok, %Comment{}}

      iex> create_comment(scope, article, %{body: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(%Scope{} = scope, %Article{} = article, attrs) do
    result =
      %Comment{}
      |> Comment.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:user, scope.user)
      |> Ecto.Changeset.put_assoc(:article, article)
      |> Repo.insert()

    case result do
      {:ok, comment} ->
        comment = Repo.preload(comment, :user)
        broadcast_comment(article.id, {:comment_created, comment})

        # Send email notification asynchronously
        Task.start(fn ->
          BlogNotifier.deliver_new_comment_notification(article, comment, scope.user)
        end)

        {:ok, comment}

      error ->
        error
    end
  end

  @doc """
  Deletes a comment.

  Only the comment owner or an admin can delete a comment.

  ## Examples

      iex> delete_comment(scope, comment)
      {:ok, %Comment{}}

      iex> delete_comment(scope, comment)
      {:error, :unauthorized}

  """
  def delete_comment(%Scope{} = scope, %Comment{} = comment) do
    is_owner = comment.user_id == scope.user.id
    is_admin = scope.user.role == "admin"

    if is_owner or is_admin do
      case Repo.delete(comment) do
        {:ok, deleted_comment} ->
          broadcast_comment(comment.article_id, {:comment_deleted, deleted_comment})
          {:ok, deleted_comment}

        error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  # Article Visits

  @doc """
  Records a visit to an article for the current day.
  Uses upsert to increment the counter if a record already exists.
  """
  def record_article_visit(article_id) do
    today = Date.utc_today()

    Repo.insert(
      %ArticleVisit{article_id: article_id, date: today, visit_count: 1},
      on_conflict: [inc: [visit_count: 1]],
      conflict_target: [:article_id, :date]
    )
  end

  @doc """
  Gets visit statistics for a specific date.
  Returns a list of maps with article title and visit count.
  """
  def get_visits_for_date(date) do
    from(v in ArticleVisit,
      join: a in Article,
      on: v.article_id == a.id,
      where: v.date == ^date,
      select: %{article_id: a.id, title: a.title, visit_count: v.visit_count}
    )
    |> Repo.all()
  end

  @doc """
  Gets visit statistics for yesterday and sends a digest email if there were visits.
  Returns :ok or {:error, reason}.
  """
  def send_daily_visit_digest do
    yesterday = Date.add(Date.utc_today(), -1)
    visits = get_visits_for_date(yesterday)

    if Enum.any?(visits) do
      date_string = Calendar.strftime(yesterday, "%B %d, %Y")
      BlogNotifier.deliver_daily_visit_digest(visits, date_string)
    else
      {:ok, :no_visits}
    end
  end
end
