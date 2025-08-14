defmodule LiveStoreWeb.Admin.ProductLive.Index do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Product

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Products
      <:actions>
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
      <:col :let={{_id, product}} label="URL">{"/products/#{product.slug}"}</:col>
      <:col :let={{_id, product}} label="Description">{preview(product.description)}</:col>
      <:col :let={{_id, product}} label="Price">{money(product.price)}</:col>
      <:col :let={{_id, product}} label="Product Attributes">
        {Enum.join(product.attribute_types, ", ")}
      </:col>

      <:action :let={{_id, product}}>
        <.link navigate={~p"/admin/products/#{product}/variants"}>Manage Variants</.link>
      </:action>
      <:action :let={{_id, product}}>
        <div class="sr-only">
          <.link navigate={~p"/admin/products/#{product}"}>Show</.link>
        </div>
        <.link patch={~p"/admin/products/#{product}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, product}}>
        <.link
          phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket |> stream(:products, Store.list_products()) |> assign(:page_title, "Listing products")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Store.get_product!(id)
    {:ok, _} = Store.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end
end
