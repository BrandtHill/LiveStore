defmodule LiveStore.Orders.Order do
  use Ecto.Schema

  import Ecto.Changeset

  alias LiveStore.Accounts.User
  alias LiveStore.Orders.OrderItem
  alias LiveStore.Orders.ShippingDetails

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "orders" do
    belongs_to :user, User

    has_many :items, OrderItem

    field :total, :integer
    field :amount_shipping, :integer
    field :amount_tax, :integer
    field :stripe_checkout_id, :string
    field :stripe_payment_id, :string
    field :tracking_number, :string

    field :status, Ecto.Enum,
      values: [:processing, :shipped, :complete, :canceled, :refunded],
      default: :processing

    embeds_one :shipping_details, ShippingDetails

    timestamps()
  end

  @required_fields [
    :status,
    :total,
    :stripe_checkout_id,
    :stripe_payment_id,
    :user_id,
    :amount_shipping,
    :amount_tax
  ]
  @allowed_fields @required_fields ++ [:tracking_number]

  @doc false
  def changeset(order \\ %__MODULE__{}, params) do
    order
    |> cast(params, @allowed_fields)
    |> cast_assoc(:items, required: true)
    |> cast_embed(:shipping_details, required: true)
    |> validate_required(@required_fields)
    |> validate_number(:total, greater_than_or_equal_to: 0)
    |> validate_number(:amount_shipping, greater_than_or_equal_to: 0)
    |> validate_number(:amount_tax, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:stripe_checkout_id)
    |> unique_constraint(:stripe_payment_id)
    |> unique_constraint(:tracking_number)
  end

  def statuses do
    Ecto.Enum.values(__MODULE__, :status)
  end
end
