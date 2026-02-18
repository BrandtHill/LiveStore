defmodule LiveStoreWeb.ShopLive.Index do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store

  import LiveStoreWeb.ShopLive.BreadcrumbComponent
  import LiveStoreWeb.ShopLive.ProductCardComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.breadcrumb {assigns} />

      <.header>
        Shop!
      </.header>

      <div class="xl:mx-12 my-8 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 justify-center gap-4 px-4">
        <.product_card :for={product <- @products} product={product} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"categories" => cat_url_segments} = _params, _url, socket) do
    with ltree_path <- url_segments_to_category_ltree(cat_url_segments),
         %{} = selected_category <- Store.get_category_by_path(ltree_path),
         [_ | _] = categories <- Store.get_category_ancestry(selected_category),
         [_ | _] = products <- Store.query_products_by_category(selected_category) do
      {:noreply,
       assign(socket,
         categories: categories,
         selected_category: selected_category,
         products: products
       )}
    else
      _ ->
        {:noreply, push_patch(socket, to: ~p"/products")}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, products: Store.query_products(), categories: [])}
  end
end
