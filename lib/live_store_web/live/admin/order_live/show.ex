defmodule LiveStoreWeb.Admin.OrderLive.Show do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="max-w-4xl mx-auto">
        <div class="space-y-4 grid grid-cols-1 sm:grid-cols-2">
          <div>
            <h3 class="font-semibold text-lg">Order Number</h3>
            <p class="text-sm opacity-80">#{@order.id}</p>
          </div>

          <div>
            <h3 class="font-semibold text-lg">Order Date</h3>
            <p class="text-sm opacity-80">{DateTime.to_date(@order.inserted_at)}</p>
          </div>

          <div class="max-w-xs">
            <h3 class="font-semibold text-lg">Tracking Number</h3>
            <form phx-submit="save" phx-change="validate">
              <.input type="text" name="tracking_number" value={@order.tracking_number} />
              <.button
                disabled={@order.tracking_number == @tracking_number}
                phx-disable-with="Saving..."
              >
                Save Tracking Number
              </.button>
            </form>
          </div>
          <div>
            <h3 class="font-semibold text-lg">Status</h3>
            <span class="badge badge-outline badge-lg capitalize">
              {@order.status}
            </span>
          </div>

          <div class="mt-6">
            <h3 class="font-semibold text-lg mb-2">Shipping Details</h3>
            <div class="text-sm opacity-80 space-y-1">
              <p>{@order.shipping_details.name}</p>
              <p>{@order.shipping_details.street}</p>
              <p>{@order.shipping_details.street_additional}</p>
              <p>
                {@order.shipping_details.city}, {@order.shipping_details.state} {@order.shipping_details.postal_code}
              </p>
              <p>{@order.shipping_details.country}</p>
              <p>{@order.shipping_details.phone}</p>
            </div>
          </div>

          <div>
            <h3 class="font-semibold text-lg">Payment Reference</h3>
            <p class="text-sm opacity-80">{@order.stripe_payment_id}</p>
          </div>
        </div>

        <div class="max-w-2xl mt-2">
          <h3 class="font-semibold text-lg mb-2">Order Items</h3>
          <.table id="order-table" rows={@order.items}>
            <:col :let={item} label="Item">
              <div>{item.variant.product.name}</div>
              <div :for={attr <- item.variant.attributes} class="text-xs pl-2 opacity-60">
                {attr.type}: {attr.value}
              </div>
            </:col>
            <:col :let={item} label="SKU">{item.variant.sku}</:col>
            <:col :let={item} label="Quantity">{item.quantity}</:col>
            <:col :let={item} label="Subtotal">{money(item.price * item.quantity)}</:col>
          </.table>

          <h3 class="font-semibold text-lg mb-2">Order Summary</h3>
          <div class="bg-base-200/20 rounded-lg p-3 space-y-1 max-w-xs sm:max-w-xs">
            <div class="flex justify-between text-sm">
              <span class="opacity-80">Subtotal</span>
              <span class="font-mono">
                {money(@order.total - @order.amount_shipping - @order.amount_tax)}
              </span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="opacity-80">Shipping</span>
              <span class="font-mono">{money(@order.amount_shipping)}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="opacity-80">Tax</span>
              <span class="font-mono">{money(@order.amount_tax)}</span>
            </div>
            <div class="border-t border-base-300 pt-2 flex justify-between items-center">
              <span class="font-semibold text-lg">Order Total</span>
              <span class="font-mono text-xl font-bold">{money(@order.total)}</span>
            </div>
          </div>
        </div>

        <.back navigate={~p"/admin/orders"}>Orders</.back>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    order = Store.get_order(id)
    {:ok, assign(socket, order: order, tracking_number: order.tracking_number)}
  end

  @impl true
  def handle_event("validate", %{"tracking_number" => tracking_number}, socket) do
    {:noreply, assign(socket, tracking_number: tracking_number)}
  end

  def handle_event("save", %{"tracking_number" => tracking_number}, socket) do
    {:ok, order} = Store.set_order_tracking_number(socket.assigns.order, tracking_number)

    {:noreply, assign(socket, order: order, tracking_number: tracking_number)}
  end
end
