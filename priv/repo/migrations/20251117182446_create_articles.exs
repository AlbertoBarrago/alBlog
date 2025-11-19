defmodule Alblog.Repo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add :title, :text, null: false
      add :slug, :text
      add :content, :text, null: false
      add :published_at, :utc_datetime
      add :category, :string
      add :author_id, references(:users, on_delete: :nothing), null: false
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:articles, [:user_id])

    create unique_index(:articles, [:slug])
    create index(:articles, [:author_id])
  end
end
