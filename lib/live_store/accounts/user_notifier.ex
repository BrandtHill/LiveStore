defmodule LiveStore.Accounts.UserNotifier do
  import Swoosh.Email

  alias LiveStore.Mailer
  alias LiveStore.Accounts.ContactForm
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

  @doc """
  Deliver email after an order status changed to `:shipped`.
  """
  def deliver_order_shipped(%User{} = user, order) do
    template = Emails.order_shipped(%{order: order})
    html = Emails.heex_to_html(template)

    deliver(user.email, "Order Shipped", html)
  end

  @doc """
  Delivers a text-based email to the configured store email (from itself) based on a user-submitted
  contact form. The reply-to address is that of the user, not the store email
  """
  def deliver_contact_form(%User{email: user_email}, %ContactForm{} = contact_form) do
    store_email = LiveStore.Config.store_email()
    store_name = LiveStore.Config.store_name()

    email =
      new()
      |> to({store_name, store_email})
      |> from({store_name, store_email})
      |> subject("#{store_name} Contact Form Submission from #{user_email}")
      |> reply_to(user_email)
      |> text_body("""
      #{user_email} submitted a contact form for #{store_name} with the following content:

      #{contact_form.content}
      """)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end
end
