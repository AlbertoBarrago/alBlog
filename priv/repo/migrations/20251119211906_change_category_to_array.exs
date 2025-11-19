defmodule Alblog.Repo.Migrations.ChangeCategoryToArray do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      remove :category
      add :category, {:array, :string}, default: []
    end
  end
end
