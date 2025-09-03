defmodule LiveStore.Orders.ShippingDetails do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :phone, :string
    field :street, :string
    field :street_additional, :string
    field :city, :string
    field :state, :string
    field :postal_code, :string
    field :country, :string
  end

  @required_fields [:name, :street, :city, :state, :postal_code, :country]
  @allowed_fields @required_fields ++ [:phone, :street_additional]

  @doc false
  def changeset(shipping_details \\ %__MODULE__{}, params) do
    shipping_details
    |> cast(params, @allowed_fields)
    |> validate_required(@required_fields)
  end
end
