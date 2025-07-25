defmodule LiveStoreWeb.ShopLive.Cart do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Cart
  alias LiveStore.Store.CartItem

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    cart = Store.preload_cart(socket.assigns.cart)

    sub_total = calculate_sub_total(cart.items)

    {:noreply, assign(socket, cart: cart, sub_total: sub_total)}
  end

  @impl true
  def handle_event("quantity", %{"item" => %{"id" => id, "quantity" => quantity}}, socket) do
    with %CartItem{id: id} = item <- Enum.find(socket.assigns.cart.items, &(&1.id == id)),
         {:ok, item} <- Store.edit_cart_item(item, quantity) do
      items =
        Enum.map(socket.assigns.cart.items, fn
          %CartItem{id: ^id} -> item
          %CartItem{} = i -> i
        end)

      update_items(socket, items)
    else
      _error -> {:noreply, put_flash(socket, :error, "Invalid quantity")}
    end
  end

  def handle_event("remove", %{"id" => id}, socket) do
    %CartItem{} = item = Enum.find(socket.assigns.cart.items, &(&1.id == id))
    {:ok, _} = Store.delete_cart_item(item)
    items = Enum.reject(socket.assigns.cart.items, &(&1.id == id))
    update_items(socket, items)
  end

  defp update_items(socket, items) do
    {:noreply,
     assign(socket,
       cart: %Cart{socket.assigns.cart | items: items},
       sub_total: calculate_sub_total(items)
     )}
  end

  defp calculate_sub_total(items) do
    Enum.sum_by(items, &((&1.variant.price_override || &1.variant.product.price) * &1.quantity))
  end
end
