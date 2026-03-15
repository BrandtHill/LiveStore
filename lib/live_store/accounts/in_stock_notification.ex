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

  def changeset(in_stock_notif \\ %__MODULE__{}, params) do
    in_stock_notif
    |> change(params)
    |> validate_required(@fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:variant)
    |> unique_constraint([:user_id, :variant_id])
  end

  def new_changeset(%User{id: user_id}, %Variant{id: variant_id}) do
    changeset(user_id: user_id, variant_id: variant_id)
  end
end
