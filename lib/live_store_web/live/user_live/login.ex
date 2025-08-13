defmodule LiveStoreWeb.UserLive.Login do
  use LiveStoreWeb, :live_view

  alias LiveStore.Accounts
  alias LiveStore.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm space-y-4">
      <div class="text-center">
        <.header>
          <p>Log in</p>
          <:subtitle>
            <%= if @current_user do %>
              You need to reauthenticate to perform sensitive actions on your account.
            <% end %>
          </:subtitle>
        </.header>
      </div>

      <div :if={local_mail_adapter?()} class="alert alert-info">
        <.icon name="hero-information-circle" class="size-6 shrink-0" />
        <div>
          <p>You are running the local mail adapter.</p>
          <p>
            To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
          </p>
        </div>
      </div>

      <.form
        :let={f}
        for={@form}
        id="login_form_magic"
        action={~p"/account/login"}
        phx-submit="submit_magic"
      >
        <.input
          readonly={!!@current_user}
          field={f[:email]}
          type="email"
          label="Email"
          autocomplete="username"
          required
          phx-mounted={JS.focus()}
        />
        <.button class="btn btn-primary w-full">
          Log in with email <span aria-hidden="true">→</span>
        </.button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_user, Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    {:ok, user} =
      case Accounts.get_user_by_email(email) do
        %User{} = user -> {:ok, user}
        nil -> Accounts.register_user(%{email: email})
      end

    Accounts.deliver_login_instructions(user, &url(~p"/account/login/#{&1}"))

    info = "You will receive email instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/account/login")}
  end

  defp local_mail_adapter? do
    Application.get_env(:live_store, LiveStore.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
