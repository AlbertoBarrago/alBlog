defmodule Alblog.Blog.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :title, :string
    field :slug, :string
    field :content, :string
    field :published_at, :utc_datetime
    field :category, :string
    field :author_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs, user_scope) do
    article
    |> cast(attrs, [:title, :slug, :content, :published_at, :category])
    |> validate_required([:title, :slug, :content, :published_at, :category])
    |> unique_constraint(:slug)
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:author_id, user_scope.user.id)
  end
end
