defmodule LiveStoreWeb.OrderLive.OrderComponents do
  use LiveStoreWeb, :html

  def large_card(assigns) do
    ~H"""
    <div class="bg-base-100 shadow rounded-lg p-6 mt-4 space-y-4">
      <div class="grid sm:grid-cols-2 gap-4">
        <div>
          <h3 class="font-semibold text-lg">Order Number</h3>
          <p class="text-sm opacity-80">#{@order.id}</p>
        </div>
        <div>
          <h3 class="font-semibold text-lg">Status</h3>
          <span class="badge badge-outline badge-lg capitalize">
            {@order.status}
          </span>
        </div>
        <div>
          <h3 class="font-semibold text-lg">Total</h3>
          <p class="font-mono">{money(@order.total)}</p>
        </div>
        <div>
          <h3 class="font-semibold text-lg">Payment Reference</h3>
          <p class="text-sm opacity-80">{@order.stripe_id}</p>
        </div>
      </div>

      <div class="mt-6">
        <h3 class="font-semibold text-lg mb-2">Shipping Details</h3>
        <div class="text-sm opacity-80 space-y-1">
          <p>{Jason.encode_to_iodata!(@order.shipping_details)}</p>
        </div>
      </div>

      <.table
        id={"order-#{@order.id}"}
        rows={@order.items}
      >
        <:col :let={item} label="Item">{item.variant.product.name}</:col>
        <:col :let={item} label="SKU">{item.variant.sku}</:col>
        <:col :let={item} label="Quantity">{item.quantity}</:col>
        <:col :let={item} label="Subtotal">{money(item.price)}</:col>
      </.table>

    </div>
    """
  end
end
