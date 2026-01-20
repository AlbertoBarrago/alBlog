defmodule Alblog.Blog.ArticleVisit do
  @moduledoc """
  Tracks daily visit counts per article for analytics and digest emails.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "article_visits" do
    field :date, :date
    field :visit_count, :integer, default: 0
    belongs_to :article, Alblog.Blog.Article

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article_visit, attrs) do
    article_visit
    |> cast(attrs, [:date, :visit_count, :article_id])
    |> validate_required([:date, :article_id])
  end
end
