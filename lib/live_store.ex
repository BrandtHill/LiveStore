defmodule LiveStore do
  @moduledoc """
  LiveStore keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defmacro __using__(_) do
    quote do
      import Ecto.Query
      alias LiveStore.Repo
      alias LiveStore.Accounts
      alias LiveStore.Accounts.ContactForm
      alias LiveStore.Accounts.InStockNotification
      alias LiveStore.Accounts.User
      alias LiveStore.Accounts.UserNotifier
      alias LiveStore.Accounts.UserToken
      alias LiveStore.Config
      alias LiveStore.Orders
      alias LiveStore.Orders.Order
      alias LiveStore.Orders.OrderItem
      alias LiveStore.Orders.ShippingDetails
      alias LiveStore.Store
      alias LiveStore.Store.Attribute
      alias LiveStore.Store.Cart
      alias LiveStore.Store.CartItem
      alias LiveStore.Store.Category
      alias LiveStore.Store.Product
      alias LiveStore.Store.Variant
      alias LiveStore.Uploads
      alias LiveStore.Uploads.Image
      :ok
    end
  end
end
