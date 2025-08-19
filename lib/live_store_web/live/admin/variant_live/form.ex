defmodule LiveStoreWeb.Admin.VariantLive.Form do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Image

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
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

          <div class="mt-6">
            <label class="block font-medium mb-2">Variant Image</label>
            <div class="grid grid-cols-[repeat(auto-fill,minmax(5rem,1fr))] gap-2">
              <label
                :for={image <- @product.images ++ [%Image{id: ""}]}
                class={[
                  "cursor-pointer rounded-lg overflow-hidden border-2 flex items-center justify-center aspect-square",
                  ((@form[:image_id].value || "") == image.id && "border-primary") ||
                    "border-transparent hover:border-base-300"
                ]}
              >
                <input
                  type="radio"
                  name={@form[:image_id].name}
                  value={image.id || ""}
                  checked={@form[:image_id].value == image.id}
                  class="hidden"
                />
                <img
                  :if={image.id != ""}
                  src={~p"/uploads/#{image.path}"}
                  class="aspect-square object-cover"
                />
                <.icon :if={image.id == ""} name="hero-x-mark" class="size-12" />
              </label>
            </div>
          </div>

          <div></div>

          <footer class="mt-8">
            <.button phx-disable-with="Saving..." variant="primary">Save Variant</.button>
            <.button navigate={~p"/admin/products/#{@product}/variants"}>Cancel</.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

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
    changeset = Store.change_variant(socket.assigns.variant, variant_params) |> IO.inspect()
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"variant" => variant_params}, socket) do
    save_product(socket, variant_params)
  end

  defp save_product(socket, variant_params) do
    case Store.upsert_variant(socket.assigns.variant, variant_params) do
      {:ok, _variant} ->
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
