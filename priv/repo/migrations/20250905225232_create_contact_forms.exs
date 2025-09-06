defmodule LiveStore.Repo.Migrations.CreateContactForms do
  use Ecto.Migration

  def change do
    create table(:contact_forms) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :content, :text
      add :opened, :boolean, default: false
      timestamps()
    end
  end
end
