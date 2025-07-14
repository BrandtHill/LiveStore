defmodule LiveStoreWeb.VariantLive.Index do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Attribute
  alias LiveStore.Store.Product
  alias LiveStore.Store.Variant

  @impl true
  def mount(%{"id" => product_id}, _session, socket) do
    %Product{variants: variants} = product = Store.get_product!(product_id)

    socket =
      socket
      |> assign(:product, product)
      |> stream(:variants, variants)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Variant")
    |> assign(:variant, Store.build_variant(socket.assigns.product))
  end

  defp apply_action(socket, :edit, %{"variant_id" => id} = _params) do
    socket
    |> assign(:page_title, "Edit Variant")
    |> assign(:variant, Store.get_variant(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Product Variants")
    |> assign(:variant, nil)
  end

  @impl true
  def handle_event(event, params, socket) do
    IO.puts("Event: #{event}")
    IO.inspect(params, label: "Params")
    {:noreply, socket}
  end

  @impl true
  def handle_info({LiveStoreWeb.VariantLive.FormComponent, {:saved, variant}}, socket) do
    socket =
      socket
      |> stream_insert(:variants, variant)
      |> assign(:product, Store.preload_variants(socket.assigns.product))

    {:noreply, socket}
  end

  def get_attr(%Variant{attributes: attributes}, type) do
    Enum.find_value(attributes, fn
      %Attribute{type: ^type, value: value} -> value
      _ -> nil
    end)
  end
end
