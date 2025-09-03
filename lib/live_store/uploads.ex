defmodule LiveStore.Uploads do
  @moduledoc """
  Context for image uploads
  """

  alias LiveStore.Repo
  alias LiveStore.Uploads.Image

  def insert_image(path) do
    Repo.insert(Image.changeset(%{path: path}))
  end

  def bulk_upsert_images(images) do
    images =
      Enum.map(
        images,
        fn i ->
          i
          |> Map.put(:inserted_at, {:placeholder, :timestamp})
          |> Map.put(:updated_at, {:placeholder, :timestamp})
          |> Map.put_new_lazy(:id, &UUIDv7.generate/0)
        end
      )

    Repo.insert_all(Image, images,
      returning: true,
      placeholders: %{timestamp: DateTime.utc_now()},
      conflict_target: [:id],
      on_conflict: {:replace_all_except, [:id, :inserted_at]}
    )
  end

  def delete_image(%Image{} = image) do
    image
    |> Image.changeset(%{})
    |> Repo.delete()
  end

  def uploads_dir() do
    Application.get_env(:live_store, :uploads_dir, "./uploads")
  end

  def full_path(name) do
    Path.join(uploads_dir(), name)
  end

  defp transparent?(image) do
    Vix.Vips.Image.has_alpha?(image) and
      image
      |> Vix.Vips.Operation.extract_band!(Vix.Vips.Image.bands(image) - 1)
      |> Vix.Vips.Operation.stats!()
      |> Vix.Vips.Image.to_list!()
      |> then(fn [[[min_alpha] | _] | _] -> min_alpha < 255 end)
  end

  def temp_save_image(path, name) do
    random = 6 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
    dest_path = full_path("TEMP__#{random}__#{name}")
    File.cp(path, dest_path)
    Path.basename(dest_path)
  end

  def process_image(temp_name, name_prefix, image_opts \\ []) do
    random = 6 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
    temp_path = full_path(temp_name)
    {:ok, image} = Vix.Vips.Image.new_from_file(temp_path)
    extension = if transparent?(image), do: "webp", else: "jpg"
    dest_path = full_path("#{name_prefix}__#{random}.#{extension}")

    Vix.Vips.Image.write_to_file(
      image,
      dest_path,
      [strip: true, access: :sequential] ++ image_opts
    )

    if String.starts_with?(temp_name, "TEMP__"), do: File.rm(temp_path)

    Path.basename(dest_path)
  end
end
