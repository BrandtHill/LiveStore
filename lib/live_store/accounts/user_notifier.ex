defmodule LiveStore.Accounts.UserNotifier do
  import Swoosh.Email

  alias LiveStore.Mailer
  alias LiveStore.Accounts.User
  alias LiveStoreWeb.Emails

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({LiveStore.Config.store_name(), LiveStore.Config.store_email()})
      |> subject(subject)
      |> html_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(%User{} = user, url) do
    template = Emails.update_email(%{user: user, url: url})
    html = Emails.heex_to_html(template)

    deliver(user.email, "Update email instructions", html)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(%User{} = user, url) do
    template = Emails.magic_link(%{user: user, url: url})
    html = Emails.heex_to_html(template)

    deliver(user.email, "Login instructions", html)
  end

  @doc """
  Deliver email after an order has been placed.
  """
  def deliver_order_confirmation(%User{} = user, order) do
    template = Emails.order_confirmation(%{order: order})
    html = Emails.heex_to_html(template)

    deliver(user.email, "Order Confirmation", html)
  end
end
