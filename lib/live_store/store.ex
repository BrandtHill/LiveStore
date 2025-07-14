defmodule LiveStore.Store do
  @moduledoc """
  The Store context.
  """

  import Ecto.Query, warn: false
  alias LiveStore.Repo

  alias LiveStore.Store.Image
  alias LiveStore.Store.Product
  alias LiveStore.Store.Variant

  ## Products

  def list_products do
    Product
    |> preload([:variants, :images])
    |> Repo.all()
  end

  def get_product!(id) do
    Product
    |> Repo.get!(id)
    |> Repo.preload([:variants, :images])
  end

  # def create_product(params \\ %{}) do
  #   %Product{}
  #   |> Product.changeset(params)
  #   |> Repo.insert()
  # end

  # def update_product(%Product{} = product, params) do
  #   product
  #   |> Product.changeset(params)
  #   |> Repo.update()
  # end

  def upsert_product(product \\ %Product{}, params) do
    product
    |> Product.changeset(params)
    |> Repo.insert_or_update()
  end

  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  def change_product(%Product{} = product, params \\ %{}) do
    Product.changeset(product, params)
  end

  def preload_variants(%Product{} = product) do
    Repo.preload(product, :variants, force: true)
  end

  ## Variants

  def get_variants(%Product{id: id}), do: get_variants(id)

  def get_variants(product_id) do
    Repo.all(from Variant, where: [product_id: ^product_id])
  end

  def get_variant(variant_id), do: Repo.get(Variant, variant_id)

  def build_variant(%Product{} = product) do
    %Variant{} = Ecto.build_assoc(product, :variants)
  end

  # def create_variant(%Product{} = product, params) do
  #   product
  #   |> build_variant()
  #   |> Variant.changeset(params)
  #   |> Repo.insert()
  # end

  # def update_variant(%Variant{} = variant, params) do
  #   variant
  #   |> Variant.changeset(params)
  #   |> Repo.update()
  # end

  def upsert_variant(%Variant{} = variant, params) do
    variant
    |> Variant.changeset(params)
    |> Repo.insert_or_update()
  end

  def change_variant(%Variant{} = variant, params \\ %{}) do
    Variant.changeset(variant, params)
  end

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
end
