defmodule LiveStoreWeb.AdminLive.Product.Show do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.header>
        Product {@product.id}
        <:subtitle>This is a product record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/admin/products/#{@product}/variants"}>Manage Variants</.button>
          <.button navigate={~p"/admin/products/#{@product}/edit"}>Edit Product</.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@product.name}</:item>
        <:item title="URL">{"/products/#{@product.slug}"}</:item>
        <:item title="Description">
          <div class="prose prose-sm max-w-none">
            {raw(HtmlSanitizeEx.markdown_html(Earmark.as_html!(@product.description || "")))}
          </div>
        </:item>
        <:item title="Price">{money(@product.price)}</:item>
        <:item title="Product Attributes">
          <ul class="list-disc list-inside">
            <li :for={attr_type <- @product.attribute_types}>{attr_type}</li>
          </ul>
        </:item>
      </.list>

      <ul class="list">
        <li class="list-row p-0"></li>
        <li class="px-4">
          <div class="font-bold py-4">Product Images</div>
          <div class="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 gap-4">
            <img
              :for={image <- @product.images}
              src={~p"/uploads/#{image.path}"}
              class="aspect-square object-cover rounded-lg"
            />
          </div>
        </li>
      </ul>

      <.back navigate={~p"/admin/products"}>Back to products</.back>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, Store.get_product!(id))}
  end

  defp page_title(:show), do: "Show Product"
  defp page_title(:edit), do: "Edit Product"
end
