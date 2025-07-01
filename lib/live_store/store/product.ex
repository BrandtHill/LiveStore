defmodule LiveStore.Store.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "products" do
    field :code, :string
    field :name, :string
    field :description, :string
    field :price, :integer
    field :thumbnail, :string

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description, :price, :thumbnail, :code])
    |> validate_required([:name, :description, :price, :thumbnail, :code])
  end
end
