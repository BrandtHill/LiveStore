defmodule LiveStoreWeb.ShopLive.Cart do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Cart
  alias LiveStore.Store.CartItem
  alias LiveStore.Stripe

  @flat_rate_shipping 500

  @impl true
  def mount(_params, _session, socket) do
    cart = Store.preload_cart(socket.assigns.cart)

    {:ok,
     socket
     |> assign(:cart, cart)
     |> assign(:sub_total, Store.calculate_total(cart))
     |> assign(:shipping, @flat_rate_shipping)
     |> assign(:stripe_public_key, Application.get_env(:live_store, :stripe_public_key))
     |> assign(:client_secret, nil)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    if socket.assigns.live_action == :checkout do
      {:ok, %{client_secret: client_secret}} = Stripe.create_checkout_session(socket.assigns.cart)
      {:noreply, assign(socket, :client_secret, client_secret)}
    else
      {:noreply, assign(socket, :client_secret, nil)}
    end
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
    cart = %Cart{socket.assigns.cart | items: items}

    {:noreply, assign(socket, cart: cart, sub_total: Store.calculate_total(cart))}
  end
end
