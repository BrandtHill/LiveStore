defmodule LiveStoreWeb.ContactLive do
  use LiveStoreWeb, :live_view

  alias LiveStore.Accounts
  alias LiveStore.Accounts.ContactForm
  alias LiveStore.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="max-w-xl mx-auto my-8">
        <.header>Contact Us</.header>
        <.form for={@form} phx-submit="save" phx-change="validate">
          <.input
            type="text"
            field={@form[:email]}
            label="Email"
            disabled={!!@current_user}
          />
          <.input
            type="textarea"
            field={@form[:content]}
            label="Content"
            phx-hook="ResizeableTextarea"
            maxlength="1000"
            placeholder={"You've reached the voicemail box of #{LiveStore.Config.store_name}. Please leave your name, number, and a brief message and we'll be sure to get back to you as soon as possible."}
          />
          <.input
            type="number"
            field={@form[:challenge]}
            label={@challenge}
            placeholder="Do the math problem"
          />
          <.button>Submit</.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {challenge, solution} = gen_math_challenge()

    {:ok,
     assign(socket,
       form: to_form(%{} |> ContactForm.changeset() |> merge_params(socket)),
       challenge: connected?(socket) && challenge || "Generating math problem... 😎",
       solution: solution
     )}
  end

  defp gen_math_challenge() do
    a = Enum.random(1..7)
    b = Enum.random(2..11)
    c = Enum.random(Stream.concat(-7..-1, 1..9))

    string = "#{a} * #{b} #{(c < 0 && "-") || "+"} #{abs(c)}"
    solution = a * b + c
    {string, solution}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    handle_event("validate", %{"contact_form" => params}, socket)
  end

  def handle_event("validate", %{"contact_form" => params}, socket) do
    changeset = params |> ContactForm.changeset() |> merge_params(socket)
    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event(
        "save",
        %{"contact_form" => params},
        %{assigns: %{solution: solution, current_user: current_user}} = socket
      ) do
    with {^solution, ""} <- Integer.parse(params["challenge"]),
         {:ok, %User{} = user} <- assert_user(current_user, params["email"]),
         {:ok, %ContactForm{}} <- Accounts.insert_contact_form(user, params["content"]) do
      {:noreply,
       socket |> put_flash(:info, "Contact submitted successfully.") |> push_navigate(to: ~p"/")}
    else
      {num, _} when is_integer(num) ->
        {challenge, solution} = gen_math_challenge()

        {:noreply,
         socket
         |> put_flash(:error, "Math challenge failed.")
         |> assign(challenge: challenge, solution: solution)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error occurred submitting contact form.")
         |> assign(:form, to_form(merge_params(changeset, socket, params)))}

      :error ->
        {:noreply, socket}
    end
  end

  defp assert_user(%User{} = user, _email), do: {:ok, user}

  defp assert_user(nil, email) do
    case Accounts.get_user_by_email(email) do
      %User{} = user -> {:ok, user}
      nil -> Accounts.register_user(%{email: email})
    end
  end

  # Don't do as I do
  defp merge_params(
         %Ecto.Changeset{params: params} = cs,
         %{assigns: %{current_user: user}},
         form_params \\ %{}
       ) do
    params =
      params
      |> Map.put_new("email", (user && user.email) || form_params["email"])
      |> Map.put_new("content", form_params["content"])
      |> Map.put_new("challenge", form_params["challenge"])

    %{cs | params: params}
  end
end
