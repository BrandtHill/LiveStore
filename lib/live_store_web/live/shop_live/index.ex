defmodule LiveStoreWeb.ShopLive.Index do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  # alias LiveStore.Store.Image
  # alias LiveStore.Store.Product
  # alias LiveStore.Store.Variant

  import LiveStoreWeb.ShopLive.ProductCardComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :products, Store.list_products())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
