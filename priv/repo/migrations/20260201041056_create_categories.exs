defmodule LiveStore.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS ltree", ""

    create table(:categories) do
      add :name, :string, null: false
      add :path, :ltree, null: false

      timestamps()
    end

    create unique_index(:categories, [:path], name: :categories_path_unique_index)
    create index(:categories, [:path], using: :gist, name: :categories_path_gist_index)

    alter table(:products) do
      add :category_id, references(:categories, on_delete: :nilify_all), null: true
    end

    create index(:products, [:category_id])
  end
end
