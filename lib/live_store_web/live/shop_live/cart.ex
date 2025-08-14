defmodule LiveStoreWeb.ShopLive.Cart do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Cart
  alias LiveStore.Store.CartItem
  alias LiveStore.Stripe

  @flat_rate_shipping 500

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8">
      <.header>Your Cart</.header>

      <p :if={@cart.items == []} class="text-base-600 text-center mt-6">Your cart is empty.</p>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-8 mt-8">
        <div class="md:col-span-2 space-y-4">
          <div
            :for={item <- @cart.items}
            class="flex gap-4 p-4 bg-base-100 rounded shadow-sm items-start border border-base-300"
          >
            <img
              src={~p"/uploads/#{hd(item.variant.product.images).path}"}
              class="w-24 h-24 object-cover rounded"
            />

            <div class="flex-grow space-y-1">
              <div class="font-semibold">{item.variant.product.name}</div>
              <span
                :for={%{type: type, value: value} <- item.variant.attributes}
                class="text-sm font-thin"
              >
                {type}: {value}{if List.last(item.variant.attributes).type != type, do: ","}
              </span>
              <div class="text-sm">SKU: {item.variant.sku}</div>
            </div>

            <div class="flex flex-col items-end justify-between h-full ml-4 max-w-[6rem]">
              <div class="text-sm font-medium">
                {money((item.variant.price_override || item.variant.product.price) * item.quantity)}
              </div>
              <div class={[
                "text-xs font-thin",
                if(item.quantity > 1, do: "visible", else: "invisible")
              ]}>
                ({money(item.variant.price_override || item.variant.product.price)} each)
              </div>
              <div class="flex items-center gap-1 w-full">
                <form phx-change="quantity" class="mt-2">
                  <input type="hidden" name="item[id]" value={item.id} />
                  <.input
                    type="number"
                    name="item[quantity]"
                    value={item.quantity}
                    min="1"
                    max={item.variant.stock}
                    phx-debounce="500"
                  />
                </form>
                <.button
                  phx-click="remove"
                  phx-value-id={item.id}
                  class="btn text-xs px-2 py-1 inline-flex items-center h-8"
                >
                  ✕
                </.button>
              </div>
            </div>
          </div>
        </div>

        <div class="border border-base-300 p-6 bg-base-100 rounded shadow-md h-fit">
          <h2 class="text-lg font-semibold text-base-800 mb-4">Order Summary</h2>
          <div class="flex justify-between text-sm mb-2">
            <span>Subtotal</span>
            <span>{money(@sub_total)}</span>
          </div>
          <div class="flex justify-between text-sm mb-2">
            <span>Shipping</span>
            <span>{money(@shipping)}</span>
          </div>
          <div class="flex justify-between text-xs my-4 text-base-700">
            <span>Tax determined at checkout</span>
          </div>
          <div class="border-t border-base-300 mt-4 pt-4 flex justify-between font-semibold text-base">
            <span>Total</span>
            <span>{money(@sub_total + @shipping)}</span>
          </div>
          <.button patch={~p"/cart/checkout"} class="btn btn-primary w-full mt-6">Checkout</.button>
        </div>
      </div>
    </div>

    <.modal :if={@live_action == :checkout} id="checkout-modal" show on_cancel={JS.patch(~p"/cart")}>
      <div
        id="stripe-checkout-element"
        phx-hook="StripeCheckout"
        data-stripe-public-key={@stripe_public_key}
        data-stripe-client-secret={@client_secret}
      >
      </div>
    </.modal>
    """
  end

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
