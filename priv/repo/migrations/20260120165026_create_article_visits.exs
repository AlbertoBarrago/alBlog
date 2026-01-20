defmodule Alblog.Repo.Migrations.CreateArticleVisits do
  use Ecto.Migration

  def change do
    create table(:article_visits) do
      add :article_id, references(:articles, on_delete: :delete_all), null: false
      add :date, :date, null: false
      add :visit_count, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:article_visits, [:article_id, :date])
    create index(:article_visits, [:date])
  end
end
