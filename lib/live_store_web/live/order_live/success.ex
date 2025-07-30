defmodule LiveStoreWeb.OrderLive.Success do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store

  @impl true
  def mount(%{"checkout_session_id" => checkout_session_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(LiveStore.PubSub, "orders:#{checkout_session_id}")
    end

    order = Store.get_order_by_stripe_id(checkout_session_id)

    {:ok, assign(socket, order: order)}
  end

  @impl true
  def handle_info({:order_created, checkout_session_id}, socket) do
    order = Store.get_order_by_stripe_id(checkout_session_id)

    {:noreply, assign(socket, order: order)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>Order Successful!!</.header>
      <div :if={@order}>
        <div>{@order.id}</div>
        <div>{money(@order.total)}</div>
        <div>{@order.stripe_id}</div>
        <div>{@order.status}</div>
      </div>
    </div>
    """
  end
end
