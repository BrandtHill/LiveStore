defmodule LiveStoreWeb.Admin.Index do
  use LiveStoreWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="mx-auto max-w-xl">
        <.header>
          Admin
          <:subtitle>
            Manage products, orders, and store settings.
          </:subtitle>
        </.header>

        <div class="divider" />

        <.button navigate={~p"/admin/settings"} variant="primary">Store Settings</.button>

        <div class="divider" />

        <.button navigate={~p"/admin/products"} variant="primary">Products</.button>

        <div class="divider" />

        <.button navigate={~p"/admin/orders"} variant="primary">Orders</.button>
      </div>
    </Layouts.app>
    """
  end
end
