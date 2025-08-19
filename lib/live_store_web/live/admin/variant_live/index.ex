defmodule LiveStoreWeb.Admin.VariantLive.Index do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Attribute
  alias LiveStore.Store.Product
  alias LiveStore.Store.Variant

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.header>
        Listing Variants for {@product.name}
        <:actions>
          <.link patch={~p"/admin/products/#{@product}/variants/new"}>
            <.button>New Variant</.button>
          </.link>
        </:actions>
      </.header>

      <.table id="variants" rows={@streams.variants}>
        <:col :let={{_id, variant}} label="SKU">{variant.sku}</:col>
        <:col :let={{_id, variant}} label="Price Override">{money(variant.price_override)}</:col>
        <:col :let={{_id, variant}} label="Stock">{variant.stock}</:col>
        <:col :let={{_id, variant}} :for={attr_type <- @product.attribute_types} label={attr_type}>
          {get_attr(variant, attr_type)}
        </:col>

        <:action :let={{_id, variant}}>
          <.link patch={~p"/admin/products/#{@product}/variants/#{variant.id}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, variant}}>
          <.link
            phx-click={JS.push("delete", value: %{id: variant.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.back navigate={~p"/admin/products/#{@product}"}>Back to product</.back>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => product_id}, _session, socket) do
    %Product{variants: variants} = product = Store.get_product!(product_id)

    socket =
      socket
      |> assign(:product, product)
      |> assign(:page_title, "Product Variants")
      |> stream(:variants, variants)

    {:ok, socket}
  end

  def get_attr(%Variant{attributes: attributes}, type) do
    Enum.find_value(attributes, fn
      %Attribute{type: ^type, value: value} -> value
      _ -> nil
    end)
  end
end
