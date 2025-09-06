defmodule LiveStoreWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use LiveStoreWeb, :controller` and
  `use LiveStoreWeb, :live_view`.
  """
  use LiveStoreWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_user, :map, default: nil

  attr :render_footer, :boolean, default: false

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <nav
      id="main-nav"
      phx-hook="NavFade"
      class="fixed z-20 w-full bg-base-100/30 transition duration-500 h-20"
    >
      <div class="px-4 h-full flex items-center justify-between">
        <div class="flex gap-2">
          <a class="flex items-center gap-2" href="/">
            <.icon name="hero-building-storefront" class="w-10 h-10 text-primary" />
            <div class="font-semibold text-xl">{LiveStore.Config.store_name()}</div>
          </a>

          <.link
            navigate={~p"/products"}
            class="px-3 py-2 rounded hover:bg-base-200 flex items-center gap-1 w-full md:w-max"
          >
            <.icon name="hero-shopping-bag" /> Shop
          </.link>
        </div>
        <.theme_toggle :if={Application.get_env(:live_store, :config_env) == :dev} />
        <div>
          <input id="nav-menu-toggle" type="checkbox" class="hidden peer" />
          <label
            for="nav-menu-toggle"
            class="cursor-pointer md:hidden p-2 rounded hover:bg-base-100"
          >
            <.icon name="hero-bars-3" class="w-6 h-6 text-base-content" />
          </label>

          <div
            id="link-wrapper"
            class="absolute top-20 right-0 w-max
        bg-base-100 md:bg-base-100/0 flex-col items-start px-4 gap-3 pb-4
        hidden peer-checked:flex mr-1
        rounded-lg shadow-xl ring-1 ring-base-100
        md:static md:flex md:flex-row md:items-center md:gap-4 md:pb-0 md:ring-0 md:shadow-none"
          >
            <.link
              :if={@current_user && @current_user.admin}
              navigate={~p"/admin"}
              class="px-3 py-2 rounded hover:bg-base-200 flex items-center gap-1 w-full md:w-max"
            >
              <.icon name="hero-wrench" /> Admin
            </.link>

            <.link
              :if={@current_user}
              navigate={~p"/account/settings"}
              class="px-3 py-2 rounded hover:bg-base-200 flex items-center gap-1 w-full md:w-max"
            >
              <.icon name="hero-user" /> Account
            </.link>

            <.link
              :if={is_nil(@current_user)}
              navigate={~p"/account/login"}
              class="px-3 py-2 rounded hover:bg-base-200 flex items-center gap-1 w-full md:w-max"
            >
              <.icon name="hero-user" /> Login
            </.link>

            <.link
              navigate={~p"/cart"}
              class="px-3 py-2 rounded hover:bg-base-200 flex items-center gap-1 w-full md:w-max"
            >
              <div class="relative">
                <.icon name="hero-shopping-cart" />

                <span
                  :if={length(@cart.items) > 0}
                  class="absolute -top-1 -right-0.5 items-center px-1 py-0.5 text-xs font-bold leading-none bg-red-400 rounded-full"
                >
                  {Enum.sum_by(@cart.items, & &1.quantity)}
                </span>
              </div>
              Cart
            </.link>
          </div>
        </div>
      </div>
    </nav>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto my-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <footer
      :if={assigns[:render_footer]}
      class="relative z-10 text-center py-6 bg-gradient-to-t from-base-300/90 via-base-300/50 to-transparent w-full"
    >
      <div class="text-md text-base-content opacity-80">
        © {Date.utc_today().year} {LiveStore.Config.store_name()} •
        <.link href={~p"/contact"} class="underline hover:text-primary transition">
          Contact Us
        </.link>
      </div>
    </footer>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
