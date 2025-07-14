defmodule LiveStore.Store.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveStore.Accounts.User
  alias LiveStore.Store.CartItem

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "carts" do
    has_many :cart_items, CartItem, preload_order: [desc: :priority]

    belongs_to :user, User

    timestamps()
  end

  @required_fields []

  @allowed_fields @required_fields ++ [:user_id]

  @doc false
  def changeset(cart \\ %__MODULE__{}, params) do
    cart
    |> cast(params, @allowed_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
  end
end
