defmodule LiveStoreWeb.ShopLive.Index do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store

  import LiveStoreWeb.ShopLive.ProductCardComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.header>
        Shop!
      </.header>

      <div class="my-8 grid grid-cols-1 sm:grid-cols-3 md:grid-cols-4 justify-center px-8">
        <.product_card :for={{_id, product} <- @streams.products} product={product} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :products, Store.list_products())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
