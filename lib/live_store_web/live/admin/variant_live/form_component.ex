defmodule LiveStoreWeb.Admin.VariantLive.FormComponent do
  use LiveStoreWeb, :live_component

  alias LiveStore.Store

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage variant records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="variant-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:sku]} type="text" label="SKU" />
        <.input field={@form[:stock]} type="number" label="Stock" />
        <.input field={@form[:price_override]} type="number" label="Price Override" />
        <i>{money(@form[:price_override].value)}</i>
        <div :for={{attr_type, index} <- Enum.with_index(@product.attribute_types, 1)}>
          <input hidden value={attr_type} name={"variant[attributes][#{index}][type]"} />
          <.input
            type="text"
            label={"Attribute #{index}: #{attr_type}"}
            value={@form.params["attributes"]["#{index}"]["value"] || get_attr(@variant, attr_type)}
            name={"variant[attributes][#{index}][value]"}
          />
          <.error :for={{msg, _} <- Keyword.get_values(get_attr_errors(@form, attr_type), :value)}>
            {msg}
          </.error>
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Variant</.button>
        </:actions>
      </.simple_form>
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
  def update(%{variant: variant, product: product} = assigns, socket) do
    attribute_map =
      product.variants
      |> Enum.flat_map(fn v -> v.attributes end)
      |> Enum.group_by(& &1.type, & &1.value)
      |> Map.new(fn {t, v} -> {t, Enum.uniq(v)} end)

    {:ok,
     socket
     |> assign(assigns)
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
        notify_parent({:saved, variant})

        action_string = (socket.assigns.action == :new && "created") || "updated"

        {:noreply,
         socket
         |> put_flash(:info, "Variant #{action_string} successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
