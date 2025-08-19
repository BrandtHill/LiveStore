defmodule LiveStore.Store.Image do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveStore.Store.Product
  alias LiveStore.Store.Variant

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "images" do
    field :path, :string
    field :priority, :integer, default: 0

    belongs_to :product, Product
    has_one :variant, Variant

    timestamps()
  end

  @required_fields [:path, :priority]

  @allowed_fields @required_fields ++ [:product_id]

  @doc false
  def changeset(image \\ %__MODULE__{}, params) do
    image
    |> cast(params, @allowed_fields)
    |> validate_required(@required_fields)
    |> validate_length(:path, max: 255)
    |> foreign_key_constraint(:product_id)
    |> unsafe_validate_unique(:path, LiveStore.Repo)
    |> unique_constraint(:path)
    |> prepare_changes(fn
      %{action: :delete} = c -> delete_file(c)
      c -> c
    end)
  end

  defp delete_file(changeset) do
    changeset
    |> get_field(:path)
    |> full_path()
    |> File.rm()

    changeset
  end

  def full_path(name) do
    Path.join([:code.priv_dir(:live_store), "static", "uploads", name])
  end
end
