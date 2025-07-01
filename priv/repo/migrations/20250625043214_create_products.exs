defmodule LiveStore.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :description, :text
      add :price, :integer
      add :thumbnail, :text
      add :code, :string

      timestamps()
    end
  end
end
