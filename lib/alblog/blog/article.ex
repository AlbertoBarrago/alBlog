defmodule Alblog.Blog.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :title, :string
    field :slug, :string
    field :content, :string
    field :published_at, :utc_datetime
    field :category, {:array, :string}, default: []
    field :author_id, :id
    belongs_to :user, Alblog.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs, user_scope) do
    article
    |> cast(attrs, [:title, :slug, :content, :published_at, :category])
    |> validate_required([:title, :content])
    |> validate_length(:title, min: 3)
    |> generate_slug()
    |> set_published_at()
    |> unique_constraint(:slug)
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:author_id, user_scope.user.id)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :title) do
      nil ->
        changeset

      title ->
        slug =
          title
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9\s-]/, "")
          |> String.replace(~r/\s+/, "-")

        put_change(changeset, :slug, slug)
    end
  end

  defp set_published_at(changeset) do
    if get_field(changeset, :published_at) do
      changeset
    else
      put_change(changeset, :published_at, DateTime.truncate(DateTime.utc_now(), :second))
    end
  end
end
