defmodule LiveStoreWeb.Admin.VariantLive.Form do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl p-4">
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage variant records in your database.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="variant-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:sku]} type="text" label="SKU" />
        <.input field={@form[:stock]} type="number" label="Stock" />
        <.input field={@form[:price_override]} type="number" label="Price Override" />
        <i>{money(@form[:price_override].value)}</i>

        <.inputs_for :let={attr} field={@form[:attributes]}>
          <.input hidden field={attr[:type]} />
          <.input
            type="text"
            field={attr[:value]}
            label={"Attribute #{attr.index + 1}: #{attr[:type].value}"}
          />
        </.inputs_for>

        <footer class="mt-8">
          <.button phx-disable-with="Saving..." variant="primary">Save Variant</.button>
          <.button navigate={~p"/admin/products/#{@product}/variants"}>Cancel</.button>
        </footer>
      </.form>
    </div>
    """
  end

  defp get_attr(variant, attr_type),
    do: LiveStoreWeb.Admin.VariantLive.Index.get_attr(variant, attr_type)

  defp get_attr_errors(%Ecto.Changeset{changes: %{attributes: [_ | _] = attributes}}, attr_type) do
    Enum.find(attributes, &(&1.changes[:type] == attr_type)).errors
  end

  defp get_attr_errors(%Phoenix.HTML.Form{source: %Ecto.Changeset{} = changeset}, attr_type),
    do: get_attr_errors(changeset, attr_type)

  defp get_attr_errors(_cs, _attr_type), do: []

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    product = Store.get_product!(id)

    variant =
      case socket.assigns.live_action do
        :new -> Store.build_variant(product)
        :edit -> Store.get_variant(params["variant_id"])
      end

    attribute_map =
      product.variants
      |> Enum.flat_map(fn v -> v.attributes end)
      |> Enum.group_by(& &1.type, & &1.value)
      |> Map.new(fn {t, v} -> {t, Enum.uniq(v)} end)

    {:ok,
     socket
     |> assign(:product, product)
     |> assign(:variant, variant)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:attribute_map, attribute_map)
     |> assign_new(:form, fn ->
       to_form(Store.change_variant(variant))
     end)}
  end

  @impl true
  def handle_event("validate", %{"variant" => variant_params}, socket) do
    changeset = Store.change_variant(socket.assigns.variant, variant_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"variant" => variant_params}, socket) do
    save_product(socket, variant_params)
  end

  defp save_product(socket, variant_params) do
    case Store.upsert_variant(socket.assigns.variant, variant_params) do
      {:ok, variant} ->
        action_string = (socket.assigns.live_action == :new && "created") || "updated"

        {:noreply,
         socket
         |> put_flash(:info, "Variant #{action_string} successfully")
         |> push_navigate(to: ~p"/admin/products/#{socket.assigns.product}/variants")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp page_title(:new), do: "New variant"
  defp page_title(:edit), do: "Edit variant"
end
