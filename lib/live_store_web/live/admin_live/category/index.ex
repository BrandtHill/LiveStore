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
          <.admin_breadcrumb ancestors={@ancestors} />
        </div>

        <%= if @parent && @parent.leaf? do %>
          <div class="text-sm font-semibold mx-2 text-base-content">
            <p>This is a leaf category that products can be added to.</p>
            <p>Or, a new leaf category can be created to turn this into a parent category.</p>
          </div>
        <% else %>
          <.table
            id="categories"
            rows={@streams.categories}
            row_click={
              fn {_, c} -> JS.navigate(~p"/admin/products/categories/#{category_to_url(c)}") end
            }
          >
            <:col :let={{_id, category}} label="Name">{category.name}</:col>
            <:col :let={{_id, category}} label="Path">{category.path}</:col>
            <:action :let={{_id, category}}>
              <.button navigate={~p"/admin/products/categories/#{category}/edit"}>Edit</.button>
            </:action>
            <:action :let={{id, category}}>
              <.button
                phx-click={JS.push("delete", value: %{id: category.id}) |> hide("##{id}")}
                data-confirm="Are you sure? Child categories will be reparented."
              >
                Delete
              </.button>
            </:action>
          </.table>
        <% end %>

        <.back navigate={back_url(@ancestors)}>Back</.back>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :categories, [])}
  end

  @impl true
  def handle_params(%{"categories" => [] = _url_segments} = _params, _url, socket) do
    {:noreply, socket |> assign(parent: nil, ancestors: []) |> update_categories()}
  end

  def handle_params(%{"categories" => url_segments} = _params, _url, socket) do
    case url_segments |> url_segments_to_ltree() |> Store.get_category_ancestry() do
      [] ->
        {:noreply, push_patch(socket, to: ~p"/admin/products/categories")}

      [_ | _] = ancestors ->
        {:noreply,
         socket
         |> assign(ancestors: ancestors, parent: List.last(ancestors))
         |> update_categories()}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Store.get_category(id)

    {:ok, _category} = Store.delete_category(category)

    {:noreply, socket |> update_categories()}
  end

  defp update_categories(socket) do
    categories = Store.get_categories(socket.assigns.parent)

    socket
    |> stream(:categories, categories, reset: true)
    |> update(:parent, fn
      %Category{} = p -> %Category{p | leaf?: categories == []}
      nil -> nil
    end)
  end

  defp back_url([]), do: ~p"/admin/products"
  defp back_url([_]), do: ~p"/admin/products/categories"

  defp back_url(ancestors) do
    c = Enum.at(ancestors, -2)
    ~p"/admin/products/categories/#{category_to_url(c)}"
  end
end
