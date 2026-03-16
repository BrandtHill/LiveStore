defmodule LiveStoreWeb.ShopLive.Index do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Category

  import LiveStoreWeb.CategoryComponents
  import LiveStoreWeb.ShopLive.ProductCardComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns} render_footer={false}>
      <.breadcrumb ancestors={@ancestors} categories={@categories} />

      <.header>
        <%= if @products == [] do %>
          No products found
        <% else %>
          Shop!
        <% end %>
      </.header>

      <div class="xl:mx-12 my-8 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 justify-center gap-4 px-4">
        <.product_card :for={product <- @products} product={product} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "All Products")}
  end

  @impl true
  def handle_params(%{"categories" => url_segments} = _params, _url, socket) do
    with ltree_path when ltree_path != "" <- url_segments_to_ltree(url_segments),
         [_ | _] = ancestors <- Store.get_category_ancestry(ltree_path),
         %Category{} = parent <- List.last(ancestors) do
      {:noreply,
       assign(socket,
         page_title: parent.name,
         ancestors: ancestors,
         categories: Store.get_categories(parent),
         products: Store.query_products_by_category(parent)
       )}
    else
      _ -> {:noreply, push_patch(socket, to: ~p"/products")}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     assign(socket,
       ancestors: [],
       categories: Store.get_categories(),
       products: Store.query_products()
     )}
  end
end
