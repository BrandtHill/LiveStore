defmodule LiveStoreWeb.OrderLive.Show do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Order

  alias LiveStoreWeb.OrderLive.OrderComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="max-w-4xl mx-auto p-6">
        <.back navigate={~p"/account/orders"}>My Orders</.back>

        <OrderComponents.large_card order={@order} phx-click="select" phx-value-id={@order.id} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    %Order{user_id: user_id} = order = Store.get_order(id)

    if socket.assigns.current_user.id == user_id do
      {:ok, assign(socket, :order, order)}
    else
      {:ok,
       socket |> put_flash(:error, "Order not found") |> push_navigate(to: ~p"/account/orders")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
