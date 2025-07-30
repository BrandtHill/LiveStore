defmodule LiveStoreWeb.StripeHandler do
  alias LiveStore.Accounts
  alias LiveStore.Accounts.User
  alias LiveStore.Store
  alias LiveStore.Store.Cart
  alias Stripe.Checkout.Session
  alias Stripe.Event

  @behaviour Stripe.WebhookHandler

  def handle_event(%Event{type: "checkout.session.completed"} = event) do
    Store.create_order(event.data.object)

    Phoenix.PubSub.broadcast(LiveStore.PubSub, "orders:#{event.data.object.id}", {:order_created, event.data.object.id})

    :ok
  end

  def handle_event(%Event{type: _type} = _event) do
    :ok
  end
end
