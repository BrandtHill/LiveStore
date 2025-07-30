defmodule LiveStore.Repo.Migrations.CreateCartAndOrderTables do
  use Ecto.Migration

  def change do
    create table(:carts) do
      add :user_id, references(:users, on_delete: :delete_all), null: true

      timestamps()
    end

    create unique_index(:carts, [:user_id])

    create table(:cart_items) do
      add :cart_id, references(:carts, on_delete: :delete_all), null: false
      add :variant_id, references(:variants, on_delete: :delete_all), null: false
      add :quantity, :integer

      timestamps()
    end

    create unique_index(:cart_items, [:cart_id, :variant_id])

    create table(:orders) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :total, :integer
      add :stripe_id, :string
      add :status, :string
      add :shipping_details, :map

      timestamps()
    end

    create index(:orders, [:user_id, :inserted_at])
    create index(:orders, [:status, :inserted_at])
    create unique_index(:orders, [:stripe_id])
  end
end
