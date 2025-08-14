defmodule LiveStore.Store.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveStore.Store.Order
  alias LiveStore.Store.Variant

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "order_items" do
    belongs_to :order, Order
    belongs_to :variant, Variant
    field :quantity, :integer
    field :price, :integer

    timestamps()
  end

  @required_fields [:order_id, :quantity, :price]

  @allowed_fields @required_fields ++ [:variant_id]

  @doc false
  def changeset(order_item \\ %__MODULE__{}, params) do
    order_item
    |> cast(params, @allowed_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:variant_id)
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> validate_number(:quantity, greater_than: 0)
  end
end
