defmodule LiveStoreWeb.Admin.ProductLive.Show do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store

  @impl true
  def render(assigns) do
    ~H"""
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
      <:item title="Product Images">
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4 mt-4">
          <div :for={image <- @product.images} class="image-row flex flex-col items-center gap-2">
            <img src={~p"/uploads/#{image.path}"} class="aspect-square object-cover w-48 rounded-lg" />
          </div>
        </div>
      </:item>
    </.list>

    <.back navigate={~p"/admin/products"}>Back to products</.back>
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
