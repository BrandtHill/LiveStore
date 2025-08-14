defmodule LiveStoreWeb.StripeHandler do
  alias LiveStore.Store
  alias Stripe.Event

  @behaviour Stripe.WebhookHandler

  def handle_event(%Event{type: "checkout.session.completed"} = event) do
    {:ok, _order} = Store.create_order(event.data.object)

    Phoenix.PubSub.broadcast(
      LiveStore.PubSub,
      "orders:#{event.data.object.id}",
      {:order_created, event.data.object.id}
    )

    :ok
  end

  def handle_event(%Event{type: _type} = _event) do
    :ok
  end
end
