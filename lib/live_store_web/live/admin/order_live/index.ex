defmodule LiveStoreWeb.Admin.OrderLive.Index do
  use LiveStoreWeb, :live_view

  alias LiveStoreWeb.OrderLive.OrderComponents

  alias LiveStore.Store

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.header>Manage Orders</.header>

      <div :for={order <- @orders}>
        <OrderComponents.small_card order={order} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :orders, Store.get_orders())}
  end

  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    {:noreply, socket}
  end
end
