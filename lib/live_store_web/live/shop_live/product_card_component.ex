defmodule LiveStoreWeb.ShopLive.ProductCardComponent do
  use LiveStoreWeb, :html

  alias LiveStore.Store.Image
  alias LiveStore.Store.Product

  def product_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/products/#{@product.slug}"}
      class="border border-base-300 rounded-lg overflow-hidden shadow hover:shadow-lg transition p-4 my-4 w-full max-w-none sm:max-w-xs"
    >
      <div class="flex flex-row sm:flex-col gap-4 items-center sm:items-stretch">
        <div class="w-40 aspect-4/3 sm:w-full sm:h-full md:aspect-square bg-base-100 flex flex-shrink-0 items-center justify-center overflow-hidden">
          <img src={image_path(@product)} class="object-cover w-full h-full" />
        </div>

        <div class="flex-1">
          <h3 class="text-lg font-semibold text-base-content truncate">{@product.name}</h3>
          <p class="text-sm text-base-content mt-1">{price_range(@product)}</p>

          <div class="mt-2">
            <%= if Enum.any?(@product.variants, & &1.stock > 0) do %>
              <span class="text-sm text-success font-medium">
                ✔ In Stock
              </span>
            <% else %>
              <span class="text-sm text-error font-medium">
                ✖ Out of Stock
              </span>
            <% end %>
          </div>
        </div>
      </div>
    </.link>
    """
  end

  defp image_path(%Product{images: [%Image{path: path} | _]}), do: ~p"/uploads/#{path}"
  defp image_path(_product), do: ~p"/images/logo.svg"

  defp price_range(%Product{variants: variants, price: price}) do
    case variants
         |> Enum.map(& &1.price_override)
         |> Enum.concat([price])
         |> Enum.filter(& &1)
         |> Enum.min_max() do
      {price, price} -> money(price)
      {low, high} -> [money(low), " - ", money(high)]
    end
  end
end
