defmodule LiveStore.StoreFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveStore.Store` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        price: 42,
        thumbnail: "some thumbnail"
      })
      |> LiveStore.Store.create_product()

    product
  end
end
