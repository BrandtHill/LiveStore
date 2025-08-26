defmodule LiveStore.Store.Order do
  use Ecto.Schema

  import Ecto.Changeset

  alias LiveStore.Accounts.User
  alias LiveStore.Store.OrderItem
  alias LiveStore.Store.ShippingDetails

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "orders" do
    belongs_to :user, User

    has_many :items, OrderItem

    field :total, :integer
    field :stripe_id, :string
    field :tracking_number, :string

    field :status, Ecto.Enum,
      values: [:processing, :canceled, :shipped, :complete, :refunded],
      default: :processing

    embeds_one :shipping_details, ShippingDetails

    timestamps()
  end

  @required_fields [:status, :total, :stripe_id, :user_id]
  @allowed_fields @required_fields ++ [:tracking_number]

  @doc false
  def changeset(order \\ %__MODULE__{}, params) do
    order
    |> cast(params, @allowed_fields)
    |> cast_assoc(:items, required: true)
    |> cast_embed(:shipping_details, required: true)
    |> validate_required(@required_fields)
    |> validate_number(:total, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:stripe_id)
    |> unique_constraint(:tracking_number)
  end
end
