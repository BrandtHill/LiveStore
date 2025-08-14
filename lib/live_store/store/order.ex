defmodule LiveStore.Store.Order do
  use Ecto.Schema

  import Ecto.Changeset

  alias LiveStore.Accounts.User
  alias LiveStore.Store.OrderItem

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "orders" do
    belongs_to :user, User

    has_many :items, OrderItem

    field :total, :integer
    field :stripe_id, :string

    field :status, Ecto.Enum,
      values: [:pending, :canceled, :shipped, :complete, :refunded],
      default: :pending

    field :shipping_details, :map

    timestamps()
  end

  @required_fields [:status, :total, :stripe_id, :user_id, :shipping_details]

  @doc false
  def changeset(order \\ %__MODULE__{}, params) do
    order
    |> cast(params, @required_fields)
    |> cast_assoc(:items, required: true)
    |> validate_required(@required_fields)
    |> validate_number(:total, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:stripe_id)
  end
end
