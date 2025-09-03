defmodule LiveStore.Store.Variant do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveStore.Store.Attribute
  alias LiveStore.Store.Product
  alias LiveStore.Uploads.Image

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "variants" do
    field :sku, :string
    field :stock, :integer, default: 0
    field :price_override, :integer

    belongs_to :product, Product
    belongs_to :image, Image

    embeds_many :attributes, Attribute, on_replace: :delete

    timestamps()
  end

  @required_fields [:sku, :stock]

  @allowed_fields @required_fields ++ [:price_override, :product_id, :image_id]

  @doc false
  def changeset(variant \\ %__MODULE__{}, params) do
    variant
    |> cast(params, @allowed_fields)
    |> cast_embed(:attributes)
    |> validate_required(@required_fields)
    |> validate_number(:stock, greater_than_or_equal_to: 0)
    |> validate_number(:price_override, greater_than_or_equal_to: 0)
    |> validate_format(:sku, ~r|^\S+$|, message: "cannot contain whitespace")
    |> foreign_key_constraint(:product_id)
    |> foreign_key_constraint(:image_id)
    |> unsafe_validate_unique(:sku, LiveStore.Repo)
    |> unique_constraint(:sku)
  end
end
