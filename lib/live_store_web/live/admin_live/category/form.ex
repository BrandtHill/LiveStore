defmodule LiveStoreWeb.AdminLive.Category.Form do
  use LiveStoreWeb, :live_view

  alias LiveStore.Store
  alias LiveStore.Store.Category

  import LiveStoreWeb.CategoryComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="mx-auto max-w-3xl p-4">
        <.header>
          {@page_title}
          <:subtitle>Manage product category names</:subtitle>
        </.header>

        <div class="mb-4">
          <.admin_breadcrumb ancestors={@ancestors} />
        </div>

        <.form
          for={@form}
          id="category-form"
          phx-debounce="0"
          phx-change="validate"
          phx-submit="save"
        >
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:path]} type="text" label="Category Path" />

          <footer class="mt-8">
            <.button phx-disable-with="Saving..." variant="primary">Save Category</.button>
            <.button navigate={@return_path}>Cancel</.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  # ----------------------------------------
  # Lifecycle
  # ----------------------------------------

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {parent, category} = get_parent_and_category(id, socket)

    {:ok,
     socket
     |> assign(:parent, parent)
     |> assign(:category, category)
     |> assign(:ancestors, Store.get_category_ancestry(parent))
     |> assign(:return_path, nav_url(parent))
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign_new(:form, fn -> to_form(Store.change_category(category)) end),
     temporary_assigns: [form: nil]}
  end

  defp get_parent_and_category("top-level", _socket), do: {nil, %Category{}}

  defp get_parent_and_category(id, %{assigns: %{live_action: :new}}),
    do: {Store.get_category(id), %Category{}}

  defp get_parent_and_category(id, %{assigns: %{live_action: :edit}}),
    do: {nil, Store.get_category(id)}

  # ----------------------------------------
  # Events
  # ----------------------------------------

  @impl true
  def handle_event("validate", %{"category" => category_params} = params, socket) do
    category_params =
      if ["category", "name"] == params["_target"] do
        Map.put(category_params, "path", path_from_name(socket, category_params["name"]))
      else
        category_params
      end

    changeset = Store.change_category(socket.assigns.category, category_params)

    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"category" => category_params}, socket) do
    case Store.upsert_category(socket.assigns.category, category_params) do
      {:ok, _category} ->
        action_string = (socket.assigns.live_action == :new && "created") || "updated"

        {:noreply,
         socket
         |> put_flash(:info, "Category #{action_string} successfully")
         |> push_navigate(to: nav_url(socket.assigns.parent))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp path_from_name(%{assigns: %{live_action: :new, parent: parent}}, name) do
    Category.path_from_parent(parent, name)
  end

  defp path_from_name(%{assigns: %{live_action: :edit, category: category}}, name) do
    Category.path_from_self(category, name)
  end

  defp nav_url(nil), do: ~p"/admin/products/categories"
  defp nav_url(parent), do: ~p"/admin/products/categories/#{category_to_url(parent)}"

  defp page_title(:new), do: "New category"
  defp page_title(:edit), do: "Edit category"
end
