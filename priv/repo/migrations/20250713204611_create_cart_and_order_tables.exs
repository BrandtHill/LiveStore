defmodule LiveStore.Repo.Migrations.CreateCartAndOrderTables do
  use Ecto.Migration

  def change do

    # Carts

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

    # Orders

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

    create table(:order_items) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :variant_id, references(:variants, on_delete: :nilify_all)
      add :quantity, :integer
      add :price, :integer

      timestamps()
    end

    create index(:order_items, [:order_id])
  end
end
