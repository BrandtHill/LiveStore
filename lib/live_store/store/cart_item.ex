defmodule LiveStore.Store.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveStore.Store.Cart
  alias LiveStore.Store.Variant

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "cart_items" do
    belongs_to :cart, Cart
    belongs_to :variant, Variant
    field :quantity, :integer

    timestamps()
  end

  @required_fields [:cart_id, :variant_id, :quantity]

  @allowed_fields @required_fields ++ []

  @doc false
  def changeset(cart_item \\ %__MODULE__{}, params) do
    cart_item
    |> cast(params, @allowed_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:cart_id)
    |> foreign_key_constraint(:variant_id)
    |> validate_number(:quantity, greater_than: 0)
  end
end
