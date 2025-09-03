defmodule LiveStore.Store.Product do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveStore.Uploads.Image
  alias LiveStore.Store.Variant

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "products" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :price, :integer
    field :attribute_types, {:array, :string}, default: []

    has_many :images, Image, preload_order: [desc: :priority]
    has_many :variants, Variant, on_replace: :delete

    timestamps()
  end

  @required_fields [:name, :slug, :price]

  @allowed_fields @required_fields ++ [:description, :attribute_types]

  @doc false
  def changeset(product \\ %__MODULE__{}, params) do
    product
    |> cast(params, @allowed_fields)
    |> cast_assoc(:variants)
    |> validate_required(@required_fields)
    |> trim_strings(:attribute_types)
    |> validate_length(:name, max: 255)
    |> validate_unique_list(:attribute_types)
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> validate_format(:slug, ~r/^[a-z0-9-]*$/)
    |> unsafe_validate_unique(:slug, LiveStore.Repo)
    |> unique_constraint(:slug)
  end

  def slug_from_name(name) do
    name
    |> String.downcase()
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/[^a-z0-9-]/, "")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end

  defp trim_strings(changeset, key) do
    put_change(changeset, key, Enum.map(get_field(changeset, key), &String.trim/1))
  end

  defp validate_unique_list(changeset, key) do
    list = get_change(changeset, key, [])

    if list == Enum.uniq(list) do
      changeset
    else
      add_error(changeset, key, "values must be unique")
    end
  end
end
