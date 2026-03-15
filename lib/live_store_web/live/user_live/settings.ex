defmodule LiveStoreWeb.UserLive.Settings do
  use LiveStoreWeb, :live_view

  alias LiveStore.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            Account Settings
            <:subtitle>Manage your account email address settings</:subtitle>
          </.header>
        </div>

        <div>
          <.button variant="primary" href={~p"/account/logout"} method="delete">
            Log out
          </.button>
        </div>

        <div class="divider" />

        <div>
          <.button variant="primary" navigate={~p"/account/orders"}>
            My Orders
          </.button>
        </div>

        <div class="divider" />

        <.label>In Stock Notifications</.label>
        <div
          :for={notif <- @current_user.in_stock_notifications}
          id={"notif-#{notif.id}"}
          class="px-4 py-1 m-2 flex flex-row items-start gap-4 flex-1
          h-18 border border-primary rounded-box"
        >
          <div class="flex-1">
            <div class="text-sm font-semibold">{notif.variant.product.name}</div>
            <span
              :for={%{type: type, value: value} <- notif.variant.attributes}
              class="text-sm font-thin"
            >
              {type}: {value}{if List.last(notif.variant.attributes).type != type, do: ","}
            </span>
            <div class="text-xs">SKU: {notif.variant.sku}</div>
          </div>
          <.button
            phx-click={JS.push("delete_notif", value: %{id: notif.id}) |> hide("#notif-#{notif.id}")}
            phx-value-id={notif.id}
            class="btn btn-ghost btn-soft btn-error btn-xs py-1 h-full"
          >
            <.icon name="hero-x-mark" class="size-6" />
          </.button>
        </div>

        <div class="divider" />

        <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
          <.input
            field={@email_form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
          />
          <.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/account/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:trigger_submit, false)
      |> update(:current_user, &Accounts.preload_in_stock_notifications/1)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/account/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("delete_notif", %{"id" => id}, socket) do
    :ok = Accounts.delete_in_stock_notification(socket.assigns.current_user, id)
    {:noreply, socket}
  end
end
