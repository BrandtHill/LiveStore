defmodule LiveStore.Accounts.InStockNotification do
  use Ecto.Schema

  import Ecto.Changeset

  alias LiveStore.Accounts.User
  alias LiveStore.Store.Variant

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec, updated_at: false

  schema "in_stock_notifications" do
    belongs_to :user, User
    belongs_to :variant, Variant
    timestamps()
  end

  @fields [:user_id, :variant_id]

  def new_changeset(%User{id: user_id}, %Variant{id: variant_id}) do
    %__MODULE__{}
    |> change(user_id: user_id, variant_id: variant_id)
    |> validate_required(@fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:variant)
    |> unique_constraint([:user_id, :variant])
  end
end
