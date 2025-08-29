defmodule LiveStoreWeb.Admin.Settings do
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
          <.input field={@form[:shipping_cost]} label="Shipping Cost" type="number" />
          <i>{money(@form[:shipping_cost].value)}</i>

          <div class="py-4">
            <.label>Background Image</.label>
            <.live_file_input upload={@uploads.background_image} class="custom-file-input" />
            <.live_img_preview
              :for={entry <- @uploads.background_image.entries}
              entry={entry}
              class="aspect-4/3 object-cover rounded-lg"
            />
          </div>

          <.button phx-disable-with="Saving..." variant="primary">Save</.button>
          <.button navigate={~p"/admin"}>Cancel</.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Store Settings",
       form: to_form(Config.get_all_for_form(), as: :settings),
       defaults: Config.get_defaults()
     )
     |> allow_upload(:background_image,
       accept: ~w(image/*),
       max_entries: 1,
       max_file_size: 20_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"settings" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params, as: :settings))}
  end

  @impl true
  def handle_event("save", %{"settings" => params}, socket) do
    background_image =
      case consume_uploaded_entries(socket, :background_image, fn %{path: path}, entry ->
             random = 6 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
             dest = LiveStore.Store.Image.full_path("#{random}__#{entry.client_name}")
             File.cp!(path, dest)
             {:ok, Path.basename(dest)}
           end) do
        [basename] -> "/uploads/#{basename}"
        _ -> nil
      end

    shipping_cost =
      try do
        String.to_integer(params["shipping_cost"])
      rescue
        _ -> nil
      end

    Config.store_name(params["store_name"])
    Config.store_subtitle(params["store_subtitle"])
    Config.store_email(params["store_email"])
    Config.shipping_cost(shipping_cost)
    Config.background_image(background_image)

    {:noreply, socket}
  end
end
