defmodule LiveStoreWeb.OrderLive.OrderComponents do
  use LiveStoreWeb, :html

  alias LiveStore.Orders.Order
  alias LiveStore.Orders.OrderItem

  def large_card(assigns) do
    ~H"""
    <div class="bg-base-100 shadow rounded-lg p-6 mt-4 space-y-4">
      <div class="grid sm:grid-cols-2 gap-4">
        <div>
          <h3 class="font-semibold text-lg">Order Number</h3>
          <p class="text-sm opacity-80">#{@order.id}</p>
        </div>
        <div>
          <h3 class="font-semibold text-lg">Order Date</h3>
          <p class="text-sm opacity-80">{DateTime.to_date(@order.inserted_at)}</p>
        </div>
        <div>
          <h3 class="font-semibold text-lg">Status</h3>
          <span class="badge badge-outline badge-lg capitalize">
            {@order.status}
          </span>
        </div>
        <div>
          <h3 class="font-semibold text-lg mb-2">Order Summary</h3>
          <div class="bg-base-200/20 rounded-lg p-3 space-y-1 max-w-xs sm:max-w-xs">
            <div class="flex justify-between text-sm">
              <span class="opacity-80">Subtotal</span>
              <span class="font-mono">
                {money(@order.total - @order.amount_shipping - @order.amount_tax)}
              </span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="opacity-80">Shipping</span>
              <span class="font-mono">{money(@order.amount_shipping)}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="opacity-80">Tax</span>
              <span class="font-mono">{money(@order.amount_tax)}</span>
            </div>
            <div class="border-t border-base-300 pt-2 flex justify-between items-center">
              <span class="font-semibold text-lg">Order Total</span>
              <span class="font-mono text-xl font-bold">{money(@order.total)}</span>
            </div>
          </div>
        </div>
        <div>
          <h3 class="font-semibold text-lg">Payment Reference</h3>
          <p class="text-sm opacity-80">{@order.stripe_payment_id}</p>
        </div>
      </div>

      <div class="mt-6">
        <h3 class="font-semibold text-lg mb-2">Shipping Details</h3>
        <div class="text-sm opacity-80 space-y-1">
          <p>{@order.shipping_details.name}</p>
          <p>{@order.shipping_details.street}</p>
          <p>{@order.shipping_details.street_additional}</p>
          <p>
            {@order.shipping_details.city}, {@order.shipping_details.state} {@order.shipping_details.postal_code}
          </p>
          <p>{@order.shipping_details.country}</p>
          <p>{@order.shipping_details.phone}</p>
        </div>
      </div>

      <.table
        id={"order-#{@order.id}"}
        rows={@order.items}
        row_click={fn item -> JS.navigate(product_url(item)) end}
      >
        <:col :let={item} label="Item">
          <div>{item.variant.product.name}</div>
          <div :for={attr <- item.variant.attributes} class="text-xs pl-2 opacity-60">
            {attr.type}: {attr.value}
          </div>
        </:col>
        <:col :let={item} label="SKU">{item.variant.sku}</:col>
        <:col :let={item} label="Quantity">{item.quantity}</:col>
        <:col :let={item} label="Subtotal">{money(item.price * item.quantity)}</:col>
      </.table>
    </div>
    """
  end

  def small_card(assigns) do
    ~H"""
    <div class="bg-base-100 shadow rounded-lg p-4 grid gap-y-2 sm:grid-cols-[50%_30%_auto] items-center hover:bg-base-200 transition">
      <span class="space-y-1">
        <div class="font-semibold">Order {@order.id}</div>
        <div class="text-sm opacity-80">{DateTime.to_date(@order.inserted_at)}</div>
      </span>

      <span class="space-y-1">
        <div class="font-medium">{money(@order.total)}</div>
        <div class="text-sm opacity-80">{order_item_count(@order)}</div>
      </span>

      <span class="badge badge-outline capitalize">
        {@order.status}
      </span>
    </div>
    """
  end

  defp product_url(%OrderItem{} = item) do
    slug = item.variant.product.slug
    sku = item.variant.sku
    ~p"/products/#{slug}?variant=#{sku}"
  end

  defp order_item_count(%Order{items: items}) do
    sum = Enum.sum_by(items, & &1.quantity)
    s = if sum > 1, do: "s"
    "#{sum} item#{s}"
  end
end
