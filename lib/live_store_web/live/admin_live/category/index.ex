defmodule LiveStoreWeb.AdminLive.Category.Index do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Category

  import LiveStoreWeb.CategoryComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="mx-auto max-w-3xl">
        <.header>
          Product Categories
          <:actions>
            <.button variant="primary" navigate={~p"/admin/products"}>
              <.icon name="hero-cube" /> Products
            </.button>
            <.button
              variant="primary"
              navigate={~p"/admin/products/categories/#{@parent || "top-level"}/new"}
            >
              <.icon name="hero-plus" /> Add Category
            </.button>
          </:actions>
        </.header>

        <div class="mb-4">
          <.admin_breadcrumb ancestors={@ancestors} categories={@categories} />
        </div>

        <div :if={@categories == []} class="text-sm text-base-content">
          This is a leaf category that products can be added
        </div>

        <.table
          :if={@categories != []}
          id="categories"
          rows={@categories}
          row_click={fn c -> JS.navigate(~p"/admin/products/categories/#{category_to_url(c)}") end}
        >
          <:col :let={category} label="Name">{category.name}</:col>
          <:col :let={category} label="Path">{category.path}</:col>
          <:action :let={category}>
            <.button navigate={~p"/admin/products/categories/#{category}/edit"}>Edit</.button>
          </:action>
          <:action :let={category}>
            <.button
              type="button"
              phx-click="delete"
              phx-value-id={category.id}
              data-confirm="Are you sure? Child categories will be reparented."
            >
              Delete
            </.button>
          </:action>
        </.table>

        <.back navigate={back_url(@ancestors)}>Back</.back>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"categories" => url_segments} = _params, _url, socket) do
    with ltree_path when ltree_path != "" <- url_segments_to_category_ltree(url_segments),
         [_ | _] = ancestors <- Store.get_category_ancestry(ltree_path),
         %Category{} = parent <- List.last(ancestors) do
      categories = Store.get_categories(parent)
      parent = %Category{parent | leaf?: categories == []}

      {:noreply, assign(socket, ancestors: ancestors, categories: categories, parent: parent)}
    else
      "" -> {:noreply, socket |> assign(parent: nil, ancestors: []) |> update_categories()}
      _ -> {:noreply, push_patch(socket, to: ~p"/admin/products/categories")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Store.get_category(id)

    {:ok, _category} = Store.delete_category(category)

    {:noreply, update_categories(socket)}
  end

  defp update_categories(socket) do
    assign(socket, categories: Store.get_categories(socket.assigns.parent))
  end

  defp back_url([]), do: ~p"/admin/products"
  defp back_url([_]), do: ~p"/admin/products/categories"

  defp back_url(ancestors) do
    c = Enum.at(ancestors, -2)
    ~p"/admin/products/categories/#{category_to_url(c)}"
  end
end
