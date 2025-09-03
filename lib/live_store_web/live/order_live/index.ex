defmodule LiveStoreWeb.OrderLive.Index do
  use LiveStoreWeb, :live_view

  alias LiveStore.Orders

  alias LiveStoreWeb.OrderLive.OrderComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="max-w-4xl mx-auto p-6">
        <.header>
          My Orders
        </.header>

        <div
          :for={order <- @orders}
          phx-click="select"
          phx-value-id={order.id}
          class={[
            "my-8 transform transition-all duration-300 ease-in-out",
            order.id == @selected && "scale-105 shadow-xl bg-base-200"
          ]}
        >
          <%= if order.id == @selected do %>
            <OrderComponents.large_card order={order} />
          <% else %>
            <div class={@selected && "opacity-50 hover:opacity-80"}>
              <OrderComponents.small_card order={order} />
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    orders = Orders.get_orders_by_user(socket.assigns.current_user)

    {:ok, assign(socket, selected: nil, orders: orders)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected, id)}
  end
end
