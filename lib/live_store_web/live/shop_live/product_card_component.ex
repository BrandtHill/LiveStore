defmodule LiveStoreWeb.ShopLive.ProductCardComponent do
  use LiveStoreWeb, :html

  alias LiveStore.Store.Image
  alias LiveStore.Store.Product

  def product_card(assigns) do
    ~H"""
    <div class="border rounded-lg overflow-hidden shadow hover:shadow-lg transition p-4 my-4 w-full max-w-none sm:max-w-xs">
      <div class="flex flex-row sm:flex-col gap-4 items-center sm:items-stretch">
        <div class="w-24 h-24 sm:w-full sm:h-full sm:aspect-square bg-gray-100 flex flex-shrink-0 items-center justify-center overflow-hidden">
          <img src={image_path(@product)} class="object-cover w-full h-full" />
        </div>

        <div class="flex-1">
          <h3 class="text-lg font-semibold text-zinc-800 truncate">{@product.name}</h3>
          <p class="text-sm text-zinc-600 mt-1">{money(@product.price)}</p>

          <div class="mt-2">
            <%= if Enum.any?(@product.variants, & &1.stock > 0) do %>
              <span class="text-sm text-green-600 font-medium">
                ✔ In Stock
              </span>
            <% else %>
              <span class="text-sm text-red-500 font-medium">
                ✖ Out of Stock
              </span>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp image_path(%Product{images: [%Image{path: path} | _]}), do: ~p"/uploads/#{path}"
  defp image_path(_product), do: ~p"/images/logo.svg"
end
