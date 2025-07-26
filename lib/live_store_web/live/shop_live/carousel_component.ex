defmodule LiveStoreWeb.ShopLive.CarouselComponent do
  use LiveStoreWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:index, fn -> 0 end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-full max-w-xl mx-auto">
      <div class="aspect-square overflow-hidden rounded-lg border shadow">
        <img
          :if={image = Enum.at(@images, @index)}
          src={~p"/uploads/#{image.path}"}
          class="object-cover w-full h-full transition duration-300 ease-in-out"
        />
      </div>

      <.button
        phx-click="prev"
        phx-target={@myself}
        class="absolute top-1/2 left-2 transform -translate-y-1/2 flex shadow opacity-80"
      >
        <.icon name="hero-chevron-left" class="w-5 h-5 text-white-800" />
      </.button>

      <.button
        phx-click="next"
        phx-target={@myself}
        class="absolute top-1/2 right-2 transform -translate-y-1/2 flex shadow opacity-80"
      >
        <.icon name="hero-chevron-right" class="w-5 h-5 text-white-800" />
      </.button>

      <div class="flex justify-center mt-3 gap-2">
        <button
          :for={{image, index} <- Enum.with_index(@images)}
          phx-click="select"
          phx-target={@myself}
          phx-value-index={index}
          class={[
            "rounded-lg overflow-hidden focus:outline-none border-2 transition",
            if(index == @index,
              do: "border-zinc-800 ring-2 ring-zinc-400",
              else: "border-transparent hover:border-zinc-300"
            )
          ]}
        >
          <img src={~p"/uploads/#{image.path}"} class="object-cover w-12 h-12" />
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("next", _params, socket) do
    index = rem(socket.assigns.index + 1, length(socket.assigns.images))
    {:noreply, assign(socket, :index, index)}
  end

  def handle_event("prev", _params, socket) do
    index = rem(socket.assigns.index - 1, length(socket.assigns.images))
    {:noreply, assign(socket, :index, index)}
  end

  def handle_event("select", %{"index" => index}, socket) do
    {:noreply, assign(socket, :index, String.to_integer(index))}
  end
end
