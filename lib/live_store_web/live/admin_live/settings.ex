defmodule LiveStoreWeb.AdminLive.Settings do
  use LiveStoreWeb, :live_view

  alias LiveStore.Config
  alias LiveStore.Uploads

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
            <div class="w-max">
              <h3 class="mt-8 mb-2 text-lg font-semibold">Shipping Countries</h3>

              <div class="space-y-2">
                <.error :for={{msg, _} <- Keyword.get_values(@form.errors, :shipping_countries)}>
                  {msg}
                </.error>
                <.country_selector
                  :for={{country, cost} <- @shipping_countries}
                  country={country}
                  cost={cost}
                  form={@form}
                />
              </div>

              <select
                name="new_country"
                class="w-full border rounded phx-3 py-2 bg-base-100 text-base-content"
              >
                <option value="">Select country</option>
                <option :for={{code, name} <- @available_countries} value={code}>
                  {name}
                </option>
              </select>
              <.button type="button" phx-click="add_country">Add country</.button>
            </div>
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

  def country_selector(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <div class="w-64">
        <.input
          type="number"
          label={"#{Config.country_name(@country)} Shipping Cost"}
          name={"settings[shipping_countries][#{@country}]"}
          value={@cost}
        />
      </div>

      <b class="pt-3 px-2 w-20">{money(@form[:shipping_countries].value[@country] || @cost)}</b>

      <.button
        type="button"
        phx-click="remove_country"
        value={@country}
        class="btn h-8.5 mt-3"
      >
        ✕
      </.button>
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
       new_country: nil,
       shipping_countries: Config.shipping_countries(),
       available_countries: Config.available_countries(),
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
  def handle_event("validate", %{"settings" => params, "new_country" => new_country}, socket) do
    changeset = Config.changeset(socket.assigns.config, params)

    {:noreply,
     assign(socket,
       form: to_form(changeset, as: :settings, action: :validate),
       new_country: if(new_country != "", do: new_country)
     )}
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

    case Config.changeset(socket.assigns.config, params) do
      %{valid?: true} = changeset ->
        Config.update(changeset)

        {:noreply,
         socket
         |> put_flash(:info, "Site settings saved successfully")
         |> push_navigate(to: ~p"/admin")}

      _changeset ->
        {:noreply, put_flash(socket, :error, "Changes are not valid")}
    end
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

  def handle_event("add_country", _params, socket) do
    shipping_countries =
      if socket.assigns.new_country do
        Map.put(socket.assigns.shipping_countries, socket.assigns.new_country, 500)
      else
        socket.assigns.shipping_countries
      end

    {:noreply, assign(socket, new_country: nil, shipping_countries: shipping_countries)}
  end

  def handle_event("remove_country", params, socket) do
    {:noreply,
     assign(socket,
       shipping_countries: Map.delete(socket.assigns.shipping_countries, params["value"])
     )}
  end

  defp consume_upload(socket, key) do
    case consume_uploaded_entries(socket, key, fn %{path: path}, entry ->
           {:ok, Uploads.temp_save_image(path, entry.client_name)}
         end) do
      [basename] -> basename
      [] -> nil
    end
  end

  defp process_image(path, name, image_opts) do
    path = Uploads.process_image(path, name, image_opts)
    "/uploads/#{path}"
  end
end
