defmodule LiveStore.Store do
  @moduledoc """
  The Store context.
  """

  import Ecto.Query, warn: false

  alias LiveStore.Accounts
  alias LiveStore.Accounts.User
  alias LiveStore.Repo
  alias LiveStore.Store.Cart
  alias LiveStore.Store.CartItem
  alias LiveStore.Store.Image
  alias LiveStore.Store.Order
  alias LiveStore.Store.Product
  alias LiveStore.Store.Variant

  alias Stripe.Checkout.Session

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

  def build_variant(%Product{} = product) do
    %Variant{} = Ecto.build_assoc(product, :variants)
  end

  def upsert_variant(%Variant{} = variant, params) do
    variant
    |> Variant.changeset(params)
    |> Repo.insert_or_update()
  end

  def change_variant(%Variant{} = variant, params \\ %{}) do
    Variant.changeset(variant, params)
  end

  ## Images

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

  ## Carts

  def fetch_user_cart(user \\ nil)
  def fetch_user_cart(%User{id: user_id}), do: fetch_user_cart(user_id)

  def fetch_user_cart(user_id) do
    %{user_id: user_id}
    |> Cart.changeset()
    |> Repo.insert!(
      returning: true,
      conflict_target: [:user_id],
      on_conflict: {:replace, [:updated_at]}
    )
    |> Repo.preload([:items])
  end

  def get_cart(id) do
    Cart
    |> Repo.get(id)
    |> Repo.preload([:items])
  end

  def preload_cart(%Cart{} = cart) do
    Repo.preload(cart, [:user, items: [variant: [product: :images]]])
  end

  def add_to_cart(%Cart{id: c_id, items: items}, %Variant{id: v_id}) do
    item = Enum.find(items, %CartItem{quantity: 0}, &(&1.variant_id == v_id))

    item
    |> CartItem.changeset(%{cart_id: c_id, variant_id: v_id, quantity: item.quantity + 1})
    |> Repo.insert_or_update()
  end

  def edit_cart_item(%CartItem{} = item, quantity) do
    item
    |> CartItem.changeset(%{quantity: quantity})
    |> Repo.update()
  end

  def delete_cart_item(%CartItem{} = item) do
    Repo.delete(item)
  end

  def calculate_total(%Cart{items: items} = _cart) do
    Enum.sum_by(items, &((&1.variant.price_override || &1.variant.product.price) * &1.quantity))
  end

  ## Orders

  def create_order(%Session{} = session) do
    {:ok, %User{} = user} =
      case Accounts.get_user_by_email(session.customer_details.email) do
        %User{stripe_id: nil} = user ->
          Accounts.update_stripe_id(user, session.customer)

        %User{} = user ->
          {:ok, user}

        nil ->
          Accounts.register_user(
            %{email: session.customer_details.email, stripe_id: session.customer},
            false
          )
      end

    %{
      stripe_id: session.id,
      user_id: user.id,
      total: session.amount_total,
      shipping_details: session.customer_details
    }
    |> Order.changeset()
    |> Repo.insert()
  end

  def get_order_by_stripe_id(stripe_id) do
    Repo.get_by(Order, stripe_id: stripe_id)
  end
end
