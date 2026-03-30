defmodule LiveStoreWeb.CategoryMenuComponent do
  use LiveStoreWeb, :live_component

  alias LiveStore.Store
  alias LiveStore.Store.Category

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <label
        class="cursor-pointer p-2 rounded hover:bg-base-100"
        phx-click="toggle"
        phx-target={@myself}
      >
        <.icon name="hero-bars-3" class="w-6 h-6 text-base-content" />
      </label>
      <div class={"#{@show && "" || "hidden"} flex flex-col absolute z-50 min-w-24 max-w-64 mt-1 bg-base-200 rounded-md shadow-black/60 shadow-xl"}>
        <%= if @selected.id do %>
          <div>
            <button
              type="button"
              phx-click="back"
              phx-target={@myself}
              class="w-full flex items-center gap-2 px-4 py-2 text-left hover:bg-base-300 hover:rounded-md"
            >
              <.icon name="hero-arrow-left" />
              <span class="truncate">{@selected.name}</span>
            </button>
          </div>
        <% end %>
        <%= for c <- @category_map[@selected.id] || [] do %>
          <div>
            <button
              type="button"
              phx-click="select_category"
              phx-target={@myself}
              phx-value-id={c.id}
              class="w-full flex items-center gap-2 px-4 py-2 text-left hover:bg-base-300 hover:rounded-md"
            >
              <span class="truncate">{c.name}</span>
              <.icon :if={not c.leaf?} name="hero-chevron-right" />
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:show, false)
     |> assign_new(:selected, fn -> %Category{} end)
     |> assign_new(:stack, fn -> [] end)
     |> assign_new(:category_map, fn %{selected: selected} ->
       %{selected.id => Store.get_categories(selected)}
     end)}
  end

  @impl true
  def handle_event(
        "select_category",
        %{"id" => id},
        %{assigns: %{category_map: category_map, selected: prev_selected}} = socket
      ) do
    selected = Enum.find(category_map[prev_selected.id], &(&1.id == id))

    category_map =
      if is_map_key(category_map, id),
        do: category_map,
        else: Map.put(category_map, id, Store.get_categories(selected))

    if selected.leaf?, do: send(self(), {:category_selected, selected})

    {:noreply,
     socket
     |> assign(selected: selected, category_map: category_map, show: not selected.leaf?)
     |> update(:stack, fn stack -> [prev_selected | stack] end)}
  end

  def handle_event("back", _params, %{assigns: %{stack: [selected | stack]}} = socket) do
    {:noreply, assign(socket, selected: selected, stack: stack)}
  end

  def handle_event("toggle", _params, socket) do
    {:noreply, update(socket, :show, fn show? -> not show? end)}
  end
end
