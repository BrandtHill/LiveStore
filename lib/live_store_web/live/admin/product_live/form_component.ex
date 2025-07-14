defmodule LiveStoreWeb.Admin.ProductLive.FormComponent do
  use LiveStoreWeb, :live_component

  alias LiveStore.Store
  alias LiveStore.Store.Image

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage product records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="product-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          phx-hook="ResizeableTextarea"
        />
        <.input field={@form[:price]} type="number" label="Price" />
        <i>{money(@form[:price].value)}</i>

        <div class="mt-4 space-y-4">
          <%= for {attr_type, index} <- Enum.with_index(@attribute_types) do %>
            <div class="flex items-bottom gap-2 my-1">
              <.input
                type="text"
                label={"Product Attribute #{index + 1}"}
                name="product[attribute_types][]"
                value={attr_type}
              />
              <.button
                class="btn btn-sm btn-outline"
                type="button"
                phx-target={@myself}
                phx-click="remove_attribute_type"
                value={attr_type}
              >
                ✕
              </.button>
            </div>
          <% end %>

          <.error :for={{msg, _} <- Keyword.get_values(@form.errors, :attribute_types)}>{msg}</.error>

          <.button
            class="btn btn-sm btn-secondary mt-2"
            type="button"
            phx-target={@myself}
            phx-click="add_attribute_type"
          >
            + Add Attribute Type
          </.button>
        </div>

        <div>
          <.label>Add Product Images</.label>
          <.live_file_input upload={@uploads.new_images} class="custom-file-input" />
          <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 mt-4">
            <div :for={image <- @all_images} class="image-row flex flex-col items-center gap-2">
              <img
                :if={image.id}
                src={~p"/uploads/#{image.path}"}
                class="aspect-square object-cover w-32 rounded-lg"
              />
              <.live_img_preview
                :if={image.ref}
                entry={Enum.find(@uploads.new_images.entries, &(&1.ref == image.ref))}
                class="aspect-square object-cover w-32 rounded-lg"
              />

              <div class="flex gap-2">
                <.button
                  :if={image.priority < length(@all_images) - 1}
                  type="button"
                  phx-click="move_img"
                  phx-target={@myself}
                  phx-value-priority={image.priority}
                  phx-value-direction={1}
                >
                  ←
                </.button>
                <.button
                  :if={image.priority > 0}
                  type="button"
                  phx-target={@myself}
                  phx-click="move_img"
                  phx-value-priority={image.priority}
                  phx-value-direction={-1}
                >
                  →
                </.button>
                <.button
                  type="button"
                  phx-click={if image.id, do: "delete_img", else: "cancel_img"}
                  phx-target={@myself}
                  phx-value-id={image.id}
                  phx-value-ref={image.ref}
                >
                  Delete
                </.button>
              </div>
            </div>
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Product</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    all_images =
      product.images
      |> Enum.map(fn i -> %{id: i.id, ref: nil, path: i.path} end)
      |> prioritize_images()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:attribute_types, product.attribute_types)
     |> assign(:all_images, all_images)
     |> assign(:deleted_image_ids, [])
     |> allow_upload(:new_images, accept: ~w(image/*), max_entries: 20)
     |> assign_new(:form, fn ->
       to_form(Store.change_product(product))
     end)}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset = Store.change_product(socket.assigns.product, product_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset, action: :validate))
     |> assign(:attribute_types, product_params["attribute_types"] || [])
     |> update_all_images()}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, product_params)
  end

  def handle_event("add_attribute_type", _params, socket) do
    {:noreply, assign(socket, :attribute_types, socket.assigns.attribute_types ++ [""])}
  end

  def handle_event("remove_attribute_type", %{"value" => value}, socket) do
    {:noreply, assign(socket, :attribute_types, socket.assigns.attribute_types -- [value])}
  end

  def handle_event("move_img", %{"priority" => p, "direction" => d}, socket) do
    all_images = socket.assigns.all_images

    index = length(all_images) - 1 - String.to_integer(p)
    swap_index = index - String.to_integer(d)

    image = Enum.at(all_images, index)
    swap_image = Enum.at(all_images, swap_index)

    all_images =
      all_images
      |> List.replace_at(swap_index, %{image | priority: swap_image.priority})
      |> List.replace_at(index, %{swap_image | priority: image.priority})

    {:noreply, assign(socket, :all_images, all_images)}
  end

  def handle_event("delete_img", %{"id" => id}, socket) do
    socket.assigns.product.images
    |> Enum.find(&(&1.id == id))
    |> Store.delete_image()

    all_images =
      socket.assigns.all_images
      |> Enum.reject(&(&1.id == id))
      |> prioritize_images()

    {:noreply, assign(socket, :all_images, all_images)}
  end

  def handle_event("cancel_img", %{"ref" => ref}, socket) do
    socket = cancel_upload(socket, :new_images, ref)

    all_images =
      socket.assigns.all_images
      |> Enum.reject(&(&1.ref == ref))
      |> prioritize_images()

    {:noreply, assign(socket, :all_images, all_images)}
  end

  defp update_all_images(socket) do
    refs = MapSet.new(socket.assigns.all_images, & &1.ref)

    new_images =
      socket.assigns.uploads.new_images.entries
      |> Enum.reject(&MapSet.member?(refs, &1.ref))
      |> Enum.map(fn entry -> %{id: nil, ref: entry.ref} end)

    all_images = prioritize_images(socket.assigns.all_images ++ new_images)

    assign(socket, :all_images, all_images)
  end

  defp prioritize_images(images) do
    images
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {image, index} -> Map.put(image, :priority, index) end)
    |> Enum.reverse()
  end

  defp save_product(socket, product_params) do
    case Store.upsert_product(socket.assigns.product, product_params) do
      {:ok, product} ->
        notify_parent({:saved, product})
        _images = upsert_images(socket, product)

        action_string = (socket.assigns.action == :new && "created") || "updated"

        {:noreply,
         socket
         |> assign(:all_images, [])
         |> put_flash(:info, "Product #{action_string} successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp upsert_images(socket, product) do
    ref_priority_map =
      socket.assigns.all_images
      |> Enum.filter(& &1.ref)
      |> Map.new(&{&1.ref, &1.priority})

    id_priority_map =
      socket.assigns.all_images
      |> Enum.filter(& &1.id)
      |> Map.new(&{&1.id, &1.priority})

    new_images =
      consume_uploaded_entries(socket, :new_images, fn %{path: path}, entry ->
        random = 6 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
        dest = Image.full_path("#{random}__#{entry.client_name}")
        File.cp!(path, dest)
        path = Path.basename(dest)
        {:ok, %{path: path, product_id: product.id, priority: ref_priority_map[entry.ref]}}
      end)

    existing_images =
      socket.assigns.all_images
      |> Enum.filter(& &1.id)
      |> Enum.map(fn i ->
        %{id: i.id, path: i.path, product_id: product.id, priority: id_priority_map[i.id]}
      end)

    {_, images} = Store.bulk_upsert_images(new_images ++ existing_images)
    images
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
