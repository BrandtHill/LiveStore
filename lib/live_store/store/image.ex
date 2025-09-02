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

  defp full_path(name) do
    Path.join([:code.priv_dir(:live_store), "static", "uploads", name])
  end

  def save_image(temp_path, name_prefix, image_opts \\ []) do
    random = 6 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
    {:ok, image} = Vix.Vips.Image.new_from_file(temp_path)
    extension = if Vix.Vips.Image.has_alpha?(image), do: "webp", else: "jpg"
    dest_path = full_path("#{name_prefix}__#{random}.#{extension}")

    Vix.Vips.Image.write_to_file(
      image,
      dest_path,
      [strip: true, access: :sequential] ++ image_opts
    )

    Path.basename(dest_path)
  end
end
