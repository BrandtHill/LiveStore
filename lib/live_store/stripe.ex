defmodule LiveStore.Stripe do
  alias LiveStore.Store
  alias LiveStore.Store.Cart
  alias Stripe.PaymentIntent
  alias Stripe.Checkout.Session

  def create_payment_intent(%Cart{} = cart) do
    PaymentIntent.create(%{
      amount: Store.calculate_total(cart),
      currency: "usd",
      payment_method_types: ["card"],
      metadata: %{"cart_id" => cart.id}
    })
  end

  def create_checkout_session(%Cart{} = cart) do
    line_items =
      Enum.map(cart.items, fn i ->
        %{
          price_data: %{
            currency: "usd",
            product_data: %{
              name: i.variant.product.name,
              description: i.variant.product.description
            },
            unit_amount: i.variant.price_override || i.variant.product.price
          },
          quantity: i.quantity
        }
      end)

    email_params = if cart.user, do: %{customer_email: cart.user.email}, else: %{}

    %{
      ui_mode: :embedded,
      mode: :payment,
      line_items: line_items,
      return_url: "http://localhost:4000/order/success?checkout_session_id={CHECKOUT_SESSION_ID}",
      automatic_tax: %{
        enabled: true
      },
      shipping_address_collection: %{
        allowed_countries: [:US]
      },
      shipping_options: [
        %{
          shipping_rate_data: %{
            display_name: "Flat rate USPS",
            fixed_amount: %{
              amount: 500,
              currency: "usd"
            },
            tax_behavior: "exclusive",
            tax_code: "txcd_92010001",
            type: "fixed_amount"
          }
        },
        %{
          shipping_rate_data: %{
            display_name: "Flat rate UPS",
            fixed_amount: %{
              amount: 800,
              currency: "usd"
            },
            tax_behavior: "exclusive",
            tax_code: "txcd_92010001",
            type: "fixed_amount"
          }
        }
      ],
      metadata: %{"cart_id" => cart.id}
    }
    |> Map.merge(email_params)
    |> Session.create()
  end
end
