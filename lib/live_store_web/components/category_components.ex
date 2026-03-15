defmodule LiveStoreWeb.CategoryComponents do
  use LiveStoreWeb, :html

  alias LiveStore.Store.Category

  attr :ancestors, :list, default: []
  attr :categories, :list, default: []
  attr :product, :map, default: nil

  def breadcrumb(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb" class="breadcrumb min-h-6 mb-2">
      <ol class="flex gap-2 text-sm font-semibold">
        <li>
          <.link {nav_or_patch(@product, ~p"/products")} class="hover:underline">All Products</.link>
        </li>

        <%= for c <- @ancestors do %>
          <li>/</li>
          <li>
            <.link
              {nav_or_patch(@product, ~p"/categories/#{category_to_url(c)}")}
              class="hover:underline"
            >
              {c.name}
            </.link>
          </li>
        <% end %>

        <%= if @categories != [] do %>
          <li class="relative">
            <button
              phx-click={show_breadcrumb_menu()}
              class="flex items-center p-1 rounded hover:bg-base-200"
            >
              <.icon
                class="breadcrumb-chevron size-4 transition-transform duration-300 ease-in-out"
                name="hero-chevron-right"
              />
            </button>

            <ul
              id="breadcrumb-menu"
              phx-click-away={hide_breadcrumb_menu()}
              class="absolute left-0 mt-2 truncate bg-base-100 border rounded-box shadow hidden flex-col"
            >
              <%= for c <- @categories do %>
                <li>
                  <.link
                    phx-click={hide_breadcrumb_menu()}
                    patch={~p"/categories/#{category_to_url(c)}"}
                    class="block px-4 py-2 m-1 hover:bg-base-200"
                  >
                    {c.name}
                  </.link>
                </li>
              <% end %>
            </ul>
          </li>
        <% end %>

        <%= if @product do %>
          <li>/</li>
          <li>
            <.link patch={~p"/products/#{@product.slug}"} class="hover:underline">
              {@product.name}
            </.link>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end

  attr :ancestors, :list, default: []
  attr :categories, :list, default: []

  def admin_breadcrumb(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb" class="breadcrumb">
      <ol class="flex gap-2 text-sm font-semibold">
        <li>
          <.link patch={~p"/admin/products/categories"} class="hover:underline">
            Top Level Categories
          </.link>
        </li>

        <%= for c <- @ancestors do %>
          <li>/</li>
          <li>
            <.link
              patch={~p"/admin/products/categories/#{category_to_url(c)}"}
              class="hover:underline"
            >
              {c.name}
            </.link>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end

  attr :category, :map, required: true

  def admin_category_link(%{category: _} = assigns) do
    ~H"""
    <.link patch={~p"/admin/products/categories/#{category_to_url(@category)}"} class="font-medium">
      {@category.name}
    </.link>
    """
  end

  defp nav_or_patch(nil = _product, url), do: [patch: url]
  defp nav_or_patch(_product, url), do: [navigate: url]

  def category_to_url(%Category{path: path}) do
    path
    |> String.downcase()
    |> String.replace("_", "-")
    |> String.split(".")
  end

  def url_segments_to_category_ltree(segments) do
    segments
    |> Enum.join(".")
    |> String.downcase()
    |> String.replace("-", "_")
  end

  defp show_breadcrumb_menu() do
    JS.show(
      to: "#breadcrumb-menu",
      transition:
        {"ease-out duration-300", "max-h-0 opacity-0 -translate-y-6",
         "max-h-[500px] opacity-100 translate-y-0"},
      time: 300
    )
    |> toggle_breadcrumb_chevron()
  end

  defp hide_breadcrumb_menu() do
    JS.hide(
      to: "#breadcrumb-menu",
      transition:
        {"ease-in duration-200", "max-h-[500px] opacity-100 translate-y-0",
         "max-h-0 opacity-0 -translate-y-6"},
      time: 200
    )
    |> toggle_breadcrumb_chevron()
  end

  defp toggle_breadcrumb_chevron(js) do
    JS.toggle_class(js, "rotate-90", to: ".breadcrumb-chevron")
  end
end
