defmodule LiveStore.Orders do
  @moduledoc """
  Context for Orders
  """

  alias LiveStore.Accounts
  alias LiveStore.Accounts.User
  alias LiveStore.Accounts.UserNotifier
  alias LiveStore.Orders.Order
  alias LiveStore.Store
  alias LiveStore.Store.Cart
  alias LiveStore.Store.CartItem
  alias LiveStore.Store.Variant
  alias LiveStore.Repo
  alias Stripe.Checkout.Session

  import Ecto.Query

  def create_order(%Session{} = session) do
    Repo.transact(fn ->
      %Cart{} = cart = Store.get_cart(session.metadata["cart_id"])
      cart = Repo.preload(cart, items: [variant: :product])

      {:ok, %User{} = user} =
        case Accounts.get_user_by_email(session.customer_details.email) do
          %User{stripe_id: nil} = user ->
            Accounts.update_stripe_id(user, session.customer)

          %User{} = user ->
            {:ok, user}

          nil ->
            Accounts.register_user(%{
              email: session.customer_details.email,
              stripe_id: session.customer
            })
        end

      order_items =
        Enum.map(cart.items, fn %CartItem{} = i ->
          i
          |> Map.take([:variant_id, :quantity])
          |> Map.put(:price, i.variant.price_override || i.variant.product.price)
        end)

      Repo.delete_all(from(i in CartItem, where: i.cart_id == ^cart.id))

      # This is an N+1 query, but not a concern for most carts.
      Enum.each(cart.items, fn i ->
        case Store.decrement_variant_stock(i.variant, i.quantity) do
          {:ok, %Variant{stock: 0, id: id}} ->
            Repo.delete_all(from CartItem, where: [variant_id: ^id])

          {:ok, %Variant{stock: stock, id: id}} ->
            Repo.update_all(
              from(ci in CartItem,
                where: [variant_id: ^id],
                update: [set: [quantity: fragment("LEAST(?, ?)", ^stock, ci.quantity)]]
              ),
              set: [updated_at: DateTime.utc_now()]
            )
        end
      end)

      shipping_details =
        session.customer_details
        |> Map.merge(session.customer_details.address)
        |> Map.put(:street, session.customer_details.address.line1)
        |> Map.put(:street_additional, session.customer_details.address.line2)

      %{
        stripe_checkout_id: session.id,
        stripe_payment_id: session.payment_intent,
        user_id: user.id,
        total: session.amount_total,
        shipping_details: shipping_details,
        items: order_items
      }
      |> Map.merge(session.total_details)
      |> Order.changeset()
      |> Repo.insert()
    end)
    |> then(fn {:ok, order} ->
      order = preload_order(order)
      Task.start(fn -> UserNotifier.deliver_order_confirmation(order.user, order) end)
      {:ok, order}
    end)
  end

  def get_order(id) do
    Order
    |> Repo.get(id)
    |> preload_order()
  end

  def get_order_by_stripe_checkout_id(stripe_id) do
    Order
    |> Repo.get_by(stripe_checkout_id: stripe_id)
    |> Repo.preload(items: [variant: :product])
  end

  def get_orders_by_user(%User{id: user_id}) do
    Repo.all(
      from o in Order,
        where: [user_id: ^user_id],
        order_by: [desc: :inserted_at],
        preload: [:user, items: [variant: :product]]
    )
  end

  def get_orders(status) do
    Repo.all(
      from Order,
        where: [status: ^status],
        order_by: [desc: :inserted_at],
        preload: [:user, :items]
    )
  end

  defp preload_order(%Order{} = order) do
    Repo.preload(order, [:user, items: [variant: :product]])
  end

  def change_tracking_number(%Order{} = order, tracking_number) do
    Order.changeset(order, %{tracking_number: tracking_number})
  end

  def set_order_tracking_number(%Order{status: :processing} = order, tracking_number) do
    {:ok, order} =
      order
      |> Order.changeset(%{tracking_number: tracking_number, status: :shipped})
      |> Repo.update()

    order = preload_order(order)
    UserNotifier.deliver_order_shipped(order.user, order)

    {:ok, order}
  end

  def set_order_tracking_number(%Order{} = order, tracking_number) do
    order
    |> Order.changeset(%{tracking_number: tracking_number})
    |> Repo.update()
  end
end
