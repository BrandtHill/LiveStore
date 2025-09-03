defmodule LiveStoreWeb.AdminLive.Order.Index do
  use LiveStoreWeb, :live_view

  alias LiveStoreWeb.OrderLive.OrderComponents

  alias LiveStore.Orders
  alias LiveStore.Orders.Order

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="max-w-6xl mx-auto">
        <.header>Manage Orders</.header>

        <form class="flex">
          <div>
            <select
              name="status"
              phx-change="select_status"
              class="w-full border rounded phx-3 py-2 bg-base-100 text-base-content capitalize"
            >
              <option :for={status <- @statuses} value={status}>{status}</option>
            </select>
          </div>
        </form>

        <div :for={order <- @orders}>
          <.link navigate={~p"/admin/orders/#{order}"}>
            <OrderComponents.small_card order={order} />
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       orders: Orders.get_orders(:processing),
       statuses: Order.statuses(),
       status: :processing
     )}
  end

  @impl true
  def handle_event("select_status", %{"status" => status}, socket) do
    status =
      case Ecto.Enum.cast_value(Order, :status, status) do
        {:ok, status} -> status
        _ -> :processing
      end

    {:noreply, assign(socket, status: status, orders: Orders.get_orders(status))}
  end
end
