defmodule LiveStore.Repo.Migrations.CreateInStockNotifications do
  use Ecto.Migration

  def change do
    create table(:in_stock_notifications) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :variant_id, references(:variants, on_delete: :delete_all), null: false
      timestamps(updated_at: false)
    end

    create unique_index(:in_stock_notifications, [:user_id, :variant_id])
    create index(:in_stock_notifications, [:variant_id])
  end
end
