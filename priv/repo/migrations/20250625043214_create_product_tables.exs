defmodule LiveStore.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    # Products

    create table(:products) do
      add :name, :citext, null: false
      add :description, :text
      add :price, :integer, null: false, default: 0
      add :attribute_types, {:array, :string}, default: []

      timestamps()
    end

    create index(:products, [:attribute_types], using: "GIN")
    create unique_index(:products, [:name])

    # Images

    create table(:images) do
      add :path, :string, null: false
      add :priority, :integer, default: 0, null: false
      add :product_id, references(:products, on_delete: :delete_all)

      timestamps()
    end

    create index(:images, [:product_id, :priority])
    create unique_index(:images, [:path])

    # Variants

    create table(:variants) do
      add :sku, :string, null: false
      add :stock, :integer, null: false
      add :price_override, :integer
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :attributes, :map, null: false

      timestamps()
    end

    create index(:variants, [:product_id])
    create unique_index(:variants, [:sku])
  end
end
