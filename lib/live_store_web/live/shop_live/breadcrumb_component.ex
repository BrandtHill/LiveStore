defmodule LiveStoreWeb.ShopLive.BreadcrumbComponent do
  use LiveStoreWeb, :html

  alias LiveStore.Store.Category

  attr :categories, :list, default: []

  def breadcrumb(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb" class="breadcrumb">
      <ol class="flex gap-2 text-sm font-semibold">
        <li>
          <.link patch={~p"/products"} class="hover:underline">All Products</.link>
        </li>

        <%= for c <- @categories do %>
          <li>/</li>
          <li>
            <.link patch={~p"/categories/#{category_to_url_segments(c)}"} class="hover:underline">
              {c.name}
            </.link>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end

  def category_to_url_segments(%Category{path: path}) do
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
end
