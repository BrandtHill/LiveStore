defmodule LiveStore.Stripe do
  alias LiveStore.Accounts.User
  alias LiveStore.Store.Cart
  alias Stripe.Checkout.Session

  def create_checkout_session(%Cart{} = cart) do
    line_items =
      Enum.map(cart.items, fn i ->
        %{
          price_data: %{
            currency: "usd",
            product_data: %{
              name: i.variant.product.name,
              description: "SKU: #{i.variant.sku}"
            },
            unit_amount: i.variant.price_override || i.variant.product.price
          },
          quantity: i.quantity
        }
      end)

    customer_params =
      case cart.user do
        nil ->
          %{customer_creation: :always}

        %User{stripe_id: nil, email: email} ->
          %{customer_email: email, customer_creation: :always}

        %User{stripe_id: stripe_id} ->
          %{customer: stripe_id, customer_update: %{shipping: :auto}}
      end

    %{
      ui_mode: :embedded,
      mode: :payment,
      line_items: line_items,
      return_url:
        "#{LiveStoreWeb.Endpoint.static_url()}/order/success?checkout_session_id={CHECKOUT_SESSION_ID}",
      automatic_tax: %{
        enabled: true
      },
      shipping_address_collection: %{
        allowed_countries: [:US]
      },
      shipping_options: [
        %{
          shipping_rate_data: %{
            display_name: "Flat rate",
            fixed_amount: %{
              amount: LiveStore.Config.shipping_cost(),
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
    |> Map.merge(customer_params)
    |> Session.create()
  end
end
