defmodule LiveStoreWeb.AdminLive.Product.Index do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.header>
        Listing Products
        <:actions>
          <.button variant="primary" navigate={~p"/admin/products/categories"}>
            <.icon name="hero-queue-list" /> Categories
          </.button>
          <.button variant="primary" navigate={~p"/admin/products/new"}>
            <.icon name="hero-plus" /> New Product
          </.button>
        </:actions>
      </.header>

      <.table
        id="products"
        rows={@streams.products}
        row_click={fn {_id, product} -> JS.navigate(~p"/admin/products/#{product}") end}
      >
        <:col :let={{_id, product}} label="Name">{product.name}</:col>
        <:col :let={{_id, product}} label="Photo">
          <img
            :if={length(product.images) > 0}
            src={image_path(product)}
            class="aspect-square object-cover rounded-lg w-20"
          />
        </:col>
        <:col :let={{_id, product}} label="URL">{"/products/#{product.slug}"}</:col>
        <:col :let={{_id, product}} label="Description">{preview(product.description)}</:col>
        <:col :let={{_id, product}} label="Price">{money(product.price)}</:col>
        <:col :let={{_id, product}} label="Product Attributes">
          {Enum.join(product.attribute_types || [], ", ")}
        </:col>
        <:col :let={{_id, product}} label="Variants">
          <.tooltip :if={product.variants == []} message="You need at least 1 variant per product.">
            <span class="flex items-center gap-1">
              <span class="text-error">{length(product.variants)}</span>
              <.icon name="hero-information-circle" class="size-3" />
            </span>
          </.tooltip>
          <span :if={product.variants != []}>
            {length(product.variants)}
          </span>
        </:col>

        <:action :let={{_id, product}}>
          <.button navigate={~p"/admin/products/#{product}/variants"}>Manage Variants</.button>
        </:action>
        <:action :let={{_id, product}}>
          <div class="sr-only">
            <.button navigate={~p"/admin/products/#{product}"}>Show</.button>
          </div>
          <.button patch={~p"/admin/products/#{product}/edit"}>Edit</.button>
        </:action>
        <:action :let={{id, product}}>
          <.button
            phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.button>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:products, Store.list_products())
     |> assign(:page_title, "Listing products")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Store.get_product!(id)
    {:ok, _} = Store.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end

  defp image_path(%{images: [%{path: path} | _]}), do: ~p"/uploads/#{path}"
end
