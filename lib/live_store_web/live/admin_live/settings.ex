defmodule LiveStoreWeb.AdminLive.Settings do
  use LiveStoreWeb, :live_view

  alias LiveStore.Config

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="mx-auto max-w-3xl">
        <.header>
          {@page_title}
          <:subtitle>Use this form to change the content of your store.</:subtitle>
        </.header>

        <.form
          for={@form}
          id="settings-form"
          phx-change="validate"
          phx-submit="save"
        >
          <.input field={@form[:store_name]} label="Store Name" placeholder={@defaults[:store_name]} />
          <.input
            field={@form[:store_subtitle]}
            label="Store Subtitle"
            placeholder={@defaults[:store_subtitle]}
          />
          <.input
            field={@form[:store_email]}
            label="Store Email"
            placeholder={@defaults[:store_email]}
          />
          <div class="flex items-center">
            <div class="w-32">
              <.input
                field={@form[:shipping_cost]}
                label="Shipping Cost"
                type="number"
                placeholder={@defaults[:shipping_cost]}
              />
            </div>
            <b class="pt-3 px-2">{money(@form[:shipping_cost].value)}</b>
          </div>

          <.image_upload label="Favicon" key={:favicon} {assigns} />
          <.image_upload label="Background Image" key={:background_image} {assigns} />

          <.button phx-disable-with="Saving..." variant="primary">Save</.button>
          <.button navigate={~p"/admin"}>Cancel</.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  def image_upload(assigns) do
    ~H"""
    <div class="py-4">
      <.label>{@label}</.label>

      <% upload = @uploads[@key] %>
      <% current = @config[@key] %>
      <% default = @defaults[@key] %>

      <.live_file_input upload={upload} class="custom-file-input" />

      <div class="max-w-xs">
        <%= cond do %>
          <% upload.entries != [] -> %>
            <.live_img_preview entry={hd(upload.entries)} class="object-cover rounded-lg" />
            <.button type="button" value={@key} phx-click="cancel_img">✕</.button>
          <% current in [nil, default] or @key in @deleted_images -> %>
            <.label>Default {@label}</.label>
            <img class="object-cover rounded-lg" src={default} />
          <% true -> %>
            <.label>Current {@label}</.label>
            <img class="object-cover rounded-lg" src={current} />
            <.button type="button" value={@key} phx-click="remove_img">✕</.button>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    config = Config.config()

    {:ok,
     socket
     |> assign(
       page_title: "Store Settings",
       form: to_form(Config.changeset(config), as: :settings),
       deleted_images: [],
       config: config,
       defaults: Config.defaults()
     )
     |> allow_upload(:background_image,
       accept: ~w(image/*),
       max_entries: 1,
       max_file_size: 20_000_000
     )
     |> allow_upload(:favicon,
       accept: ~w(image/*),
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"settings" => params}, socket) do
    changeset = Config.changeset(socket.assigns.config, params)

    {:noreply, assign(socket, :form, to_form(changeset, as: :settings, action: :validate))}
  end

  def handle_event("save", %{"settings" => params}, socket) do
    params =
      [background_image: [Q: 85], favicon: []]
      |> Map.new(fn {key, image_opts} ->
        image =
          if (path = consume_upload(socket, key)) || key in socket.assigns.deleted_images do
            path && process_image(path, key, image_opts)
          else
            socket.assigns.config[key]
          end

        {"#{key}", image}
      end)
      |> Map.merge(params)

    socket.assigns.config
    |> Config.changeset(params)
    |> Config.update()

    {:noreply,
     socket
     |> put_flash(:info, "Site settings saved successfully")
     |> push_navigate(to: ~p"/admin")}
  end

  def handle_event("remove_img", %{"value" => key}, socket) do
    key = String.to_existing_atom(key)
    {:noreply, update(socket, :deleted_images, fn images -> [key | images] end)}
  end

  def handle_event("cancel_img", %{"value" => key}, socket) do
    key = String.to_existing_atom(key)
    [%{ref: ref}] = socket.assigns.uploads[key].entries
    {:noreply, cancel_upload(socket, key, ref)}
  end

  defp consume_upload(socket, key) do
    case consume_uploaded_entries(socket, key, fn %{path: path}, entry ->
           {:ok, LiveStore.Store.Image.temp_save_image(path, entry.client_name)}
         end) do
      [basename] -> basename
      [] -> nil
    end
  end

  defp process_image(path, name, image_opts) do
    path = LiveStore.Store.Image.process_image(path, name, image_opts)
    "/uploads/#{path}"
  end
end
