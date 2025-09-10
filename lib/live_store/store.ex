defmodule LiveStore.Store do
  @moduledoc """
  The Store context.
  """

  import Ecto.Query, warn: false

  alias Ecto.UUID
  alias LiveStore.Accounts.User
  alias LiveStore.Repo
  alias LiveStore.Store.Attribute
  alias LiveStore.Store.Cart
  alias LiveStore.Store.CartItem
  alias LiveStore.Store.Product
  alias LiveStore.Store.Variant

  ## Products

  def list_products do
    Product
    |> preload([:variants, :images])
    |> Repo.all()
  end

  def query_products() do
    Repo.all(
      from p in Product,
        join: v in assoc(p, :variants),
        preload: [{:variants, v}, :images]
    )
  end

  def get_product!(id) do
    Product
    |> Repo.get!(id)
    |> Repo.preload([:variants, :images])
  end

  def get_product_by_slug!(slug) do
    Product
    |> Repo.get_by!(slug: slug)
    |> Repo.preload([:variants, :images])
  end

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

  def build_variant(%Product{attribute_types: types} = product) do
    attributes = Enum.map(types, fn type -> %Attribute{id: UUID.generate(), type: type} end)
    %Variant{} = Ecto.build_assoc(product, :variants, attributes: attributes)
  end

  def upsert_variant(%Variant{} = variant, params) do
    variant
    |> Variant.changeset(params)
    |> Repo.insert_or_update()
  end

  def decrement_variant_stock(%Variant{} = variant, quantity) do
    {1, [variant]} =
      Repo.update_all(
        from(v in Variant,
          where: [id: ^variant.id],
          update: [set: [stock: fragment("GREATEST(0, ? - ?)", v.stock, ^quantity)]],
          select: v
        ),
        set: [updated_at: DateTime.utc_now()]
      )

    {:ok, variant}
  end

  def change_variant(%Variant{} = variant, params \\ %{}) do
    Variant.changeset(variant, params)
  end

  def delete_variant(%Variant{} = variant) do
    Repo.delete(variant)
  end

  ## Carts

  def build_cart(id \\ UUIDv7.generate()) do
    %Cart{id: id, items: []}
  end

  def get_user_cart(%User{id: user_id}) do
    case Repo.get_by(Cart, user_id: user_id) do
      %Cart{} = cart -> Repo.preload(cart, :items)
      nil -> %{user_id: user_id} |> Cart.changeset() |> Repo.insert!() |> Repo.preload(:items)
    end
  end

  def get_cart(id) do
    case Repo.get(Cart, id) do
      %Cart{} = cart -> Repo.preload(cart, :items)
      nil -> build_cart(id)
    end
  end

  def persist_cart(%Cart{} = cart) do
    cart
    |> Cart.changeset(%{})
    |> Repo.insert_or_update!()
  end

  def preload_cart(%Cart{} = cart) do
    Repo.preload(cart, [:user, items: [variant: [product: :images]]])
  end

  @spec add_to_cart(%Cart{}, %Variant{}) :: {:ok, %Cart{}}
  def add_to_cart(%Cart{items: items} = cart, %Variant{id: v_id, stock: stock}) do
    cart = persist_cart(cart)
    item = Enum.find(items, %CartItem{quantity: 0}, &(&1.variant_id == v_id))

    item =
      item
      |> CartItem.changeset(%{
        cart_id: cart.id,
        variant_id: v_id,
        quantity: min(stock, item.quantity + 1)
      })
      |> Repo.insert_or_update!()

    items =
      if index = Enum.find_index(items, &(&1.id == item.id)) do
        List.replace_at(items, index, item)
      else
        items ++ [item]
      end

    {:ok, %{cart | items: items}}
  end

  def edit_cart_item(%CartItem{variant: %Variant{stock: stock}} = item, quantity) do
    item
    |> CartItem.changeset(%{quantity: min(stock, quantity)})
    |> Repo.update()
  end

  def delete_cart_item(%CartItem{} = item) do
    Repo.delete(item)
  end

  def calculate_total(%Cart{items: items} = _cart) do
    Enum.sum_by(items, &calculate_item_price/1)
  end

  defp calculate_item_price(%CartItem{variant: variant, quantity: quantity}),
    do: (variant.price_override || variant.product.price) * quantity
end
