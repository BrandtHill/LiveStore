defmodule LiveStoreWeb.AdminLive.Order.Show do
  use LiveStoreWeb, :live_view

  alias LiveStore.Orders

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
            <.form for={@form} id="tracking-number-form" phx-change="validate" phx-submit="save">
              <.input field={@form[:tracking_number]} type="text" />
              <.button
                disabled={@order.tracking_number == @form[:tracking_number].value}
                phx-disable-with="Saving..."
              >
                Save Tracking Number
              </.button>
            </.form>
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
              <p>{@order.user.email}</p>
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
    order = Orders.get_order(id)

    {:ok,
     socket
     |> assign(:order, order)
     |> assign_new(:form, fn ->
       to_form(Orders.change_tracking_number(order, order.tracking_number))
     end)}
  end

  @impl true
  def handle_event("validate", %{"order" => %{"tracking_number" => tracking_number}}, socket) do
    changeset = Orders.change_tracking_number(socket.assigns.order, tracking_number)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"order" => %{"tracking_number" => tracking_number}}, socket) do
    {:ok, order} = Orders.set_order_tracking_number(socket.assigns.order, tracking_number)

    {:noreply, assign(socket, order: order)}
  end
end
