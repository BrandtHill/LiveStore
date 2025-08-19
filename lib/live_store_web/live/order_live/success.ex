defmodule LiveStoreWeb.OrderLive.Success do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStoreWeb.OrderLive.OrderComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="max-w-4xl mx-auto p-6">
        <.header>
          🎉 Order Successful!
          <:subtitle>Thank you for your purchase, your order is now being processed.</:subtitle>
        </.header>

        <OrderComponents.large_card :if={@order} order={@order} />

        <div class="mt-8 text-center">
          <.button navigate={~p"/"} variant="primary">Continue Shopping</.button>
        </div>
      </div>
    </Layouts.app>
    """
  end

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
end
