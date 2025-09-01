defmodule LiveStoreWeb.ShopLive.ProductPage do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Attribute
  alias LiveStore.Store.Product
  alias LiveStore.Store.Variant

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="mt-8 grid grid-cols-1 md:grid-cols-2 gap-8 px-6 py-8 max-w-6xl mx-auto">
        <div>
          <.live_component
            module={LiveStoreWeb.ShopLive.CarouselComponent}
            images={@product.images}
            index={@index}
            id="product-image-carousel"
          />
        </div>

        <div class="space-y-4">
          <h1 class="text-3xl font-bold text-base-content">{@product.name}</h1>
          <div class="prose prose-sm max-w-none">
            {raw(HtmlSanitizeEx.markdown_html(Earmark.as_html!(@product.description || "")))}
          </div>

          <div>
            <span class="text-base-content text-lg pt-4 pr-2">
              {money(price(@product, @selected_variant))}
            </span>
            <%= case {@selected_variant, in_stock?(@product, @selected_variant)} do %>
              <% {nil, _} -> %>
                <span></span>
              <% {_, true} -> %>
                <span class="text-sm text-success font-medium">✔ In Stock</span>
              <% {_, false} -> %>
                <span class="text-sm text-error font-medium">✖ Out of Stock</span>
            <% end %>
          </div>

          <div class="space-y-4 mt-6">
            <form>
              <div :for={attr_type <- @product.attribute_types} class="pb-4">
                <.label>{attr_type}</.label>
                <select
                  name={"attributes[#{attr_type}]"}
                  phx-change="select_attribute"
                  class="w-full border rounded phx-3 py-2 bg-base-100 text-base-content"
                >
                  <option value="">Choose {attr_type}...</option>
                  <option
                    :for={{attr_val, disabled?} <- @attribute_map[attr_type]}
                    value={attr_val}
                    disabled={disabled?}
                    selected={@selected_attributes[attr_type] == attr_val}
                  >
                    {attr_val}
                  </option>
                </select>
              </div>
            </form>

            <span :if={@selected_variant} class="text-base-content font-medium">
              SKU: {@selected_variant.sku}
            </span>
          </div>

          <div class="flex space-x-4">
            <.button
              :if={@selected_variant && @selected_variant.stock > 0}
              phx-click="add_to_cart"
            >
              Add to Cart
            </.button>

            <.link
              class={[
                "btn btn-soft btn-primary transition-all duration-500 ease-in-out",
                (@added_to_cart && "opacity-100 scale-100") ||
                  "opacity-0 scale-95 pointer-events-none"
              ]}
              navigate={~p"/cart"}
            >
              Checkout Now
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"slug" => slug} = _params, _session, socket) do
    product = Store.get_product_by_slug!(slug)

    selected_attributes = Map.new(product.attribute_types, fn type -> {type, nil} end)

    attribute_map = create_attribute_map(product.variants, selected_attributes)

    socket =
      socket
      |> assign(:index, 0)
      |> assign(:product, product)
      |> assign(:selected_variant, nil)
      |> assign(:added_to_cart, false)
      |> assign(:attribute_map, attribute_map)
      |> assign(:selected_attributes, selected_attributes)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"variant" => sku}, _url, socket) do
    if selected_variant = Enum.find(socket.assigns.product.variants, &(&1.sku == sku)) do
      selected_attributes = Map.new(selected_variant.attributes, &{&1.type, &1.value})
      attribute_map = create_attribute_map(socket.assigns.product.variants, selected_attributes)

      {:noreply,
       assign(socket,
         selected_variant: selected_variant,
         selected_attributes: selected_attributes,
         attribute_map: attribute_map,
         index:
           Enum.find_index(socket.assigns.product.images, &(&1.id == selected_variant.image_id)) ||
             socket.assigns.index
       )}
    else
      {:noreply, assign(socket, selected_variant: nil)}
    end
  end

  def handle_params(_params, _url, socket) do
    variant =
      case socket.assigns.product.variants do
        [variant] -> variant
        _ -> nil
      end

    {:noreply, assign(socket, selected_variant: variant)}
  end

  @impl true
  def handle_event("select_attribute", %{"attributes" => attr}, socket) do
    [{type, value}] = Map.to_list(attr)

    selected_attributes = Map.put(socket.assigns.selected_attributes, type, value)

    attribute_map = create_attribute_map(socket.assigns.product.variants, selected_attributes)

    selected_variant =
      case {selectable_variants(socket.assigns.product.variants, selected_attributes), value} do
        {_variants, ""} -> nil
        {[variant], _value} -> variant
        _ -> nil
      end

    query = if selected_variant, do: %{variant: selected_variant.sku}, else: %{}

    socket =
      socket
      |> assign(:attribute_map, attribute_map)
      |> assign(:selected_attributes, selected_attributes)
      |> assign(:selected_variant, selected_variant)
      |> push_patch(to: ~p"/products/#{socket.assigns.product.slug}?#{query}")

    {:noreply, socket}
  end

  def handle_event("add_to_cart", _params, socket) do
    {:ok, item} = Store.add_to_cart(socket.assigns.cart, socket.assigns.selected_variant)

    items = socket.assigns.cart.items

    items =
      if index = Enum.find_index(items, &(&1.id == item.id)) do
        List.replace_at(items, index, item)
      else
        items ++ [item]
      end

    {:noreply, assign(socket, cart: %{socket.assigns.cart | items: items}, added_to_cart: true)}
  end

  defp create_attribute_map(variants, selected_attributes) do
    variants
    |> Enum.flat_map(fn v -> v.attributes end)
    |> Enum.group_by(& &1.type, & &1.value)
    |> Map.new(fn {type, values} ->
      selectable = selectable_attributes(variants, selected_attributes, type)

      values =
        values
        |> Enum.uniq()
        |> Enum.map(fn v -> {v, v not in selectable} end)

      {type, values}
    end)
  end

  defp selectable_attributes(variants, selected_attributes, type) do
    variants
    |> selectable_variants(Map.delete(selected_attributes, type))
    |> Enum.flat_map(fn v -> v.attributes end)
    |> Enum.filter(fn %Attribute{type: t} -> t == type end)
    |> Enum.map(fn %Attribute{value: v} -> v end)
    |> Enum.uniq()
  end

  defp selectable_variants(variants, selected_attributes) do
    Enum.reduce(selected_attributes, variants, fn {type, value}, variants ->
      variants_with_attribute(variants, type, value)
    end)
  end

  defp variants_with_attribute(variants, _, nil), do: variants
  defp variants_with_attribute(variants, _, ""), do: variants

  defp variants_with_attribute(variants, type, value) do
    Enum.filter(variants, fn %Variant{attributes: attributes} ->
      Enum.any?(attributes, fn
        %Attribute{type: ^type, value: ^value} -> true
        _attribute -> false
      end)
    end)
  end

  def in_stock?(%Product{variants: variants}, nil = _selected_variant) do
    Enum.any?(variants, &(&1.stock > 0))
  end

  def in_stock?(_product, %Variant{stock: stock}) do
    stock > 0
  end

  def price(%Product{price: price}, nil = _selected_variant) do
    price
  end

  def price(%Product{price: price}, %Variant{price_override: price_override}) do
    price_override || price
  end
end
