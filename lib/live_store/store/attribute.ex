defmodule LiveStore.Store.Attribute do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :type, :string
    field :value, :string
  end

  @doc false
  def changeset(attribute \\ %__MODULE__{}, params) do
    attribute
    |> cast(params, [:type, :value])
    |> validate_required([:type, :value])
  end
end
