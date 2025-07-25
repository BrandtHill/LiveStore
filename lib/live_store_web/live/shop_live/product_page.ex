defmodule LiveStoreWeb.ShopLive.ProductPage do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.CartItem
  alias LiveStore.Store.Attribute
  alias LiveStore.Store.Product
  alias LiveStore.Store.Variant

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    product = Store.get_product!(id)

    selected_attributes = Map.new(product.attribute_types, fn type -> {type, nil} end)

    attribute_map = create_attribute_map(product.variants, selected_attributes)

    socket =
      socket
      |> assign(:product, product)
      |> assign(:selected_variant, nil)
      |> assign(:attribute_map, attribute_map)
      |> assign(:selected_attributes, selected_attributes)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, url, socket) do
    IO.inspect(params, label: "Params")
    IO.inspect(url, label: "URL")
    IO.inspect(socket.host_uri, label: "Socket URI")
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_attribute", %{"attributes" => attr}, socket) do
    [{type, value}] = Map.to_list(attr)

    selected_attributes = Map.put(socket.assigns.selected_attributes, type, value)

    attribute_map = create_attribute_map(socket.assigns.product.variants, selected_attributes)

    selected_variant =
      case selectable_variants(socket.assigns.product.variants, selected_attributes) do
        [variant] -> variant
        _ -> nil
      end

    socket =
      socket
      |> assign(:attribute_map, attribute_map)
      |> assign(:selected_attributes, selected_attributes)
      |> assign(:selected_variant, selected_variant)

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

    {:noreply, assign(socket, :cart, %{socket.assigns.cart | items: items})}
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
