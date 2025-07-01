defmodule LiveStore.Bean do
  use Ecto.Schema

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "beans" do
    field(:type, :string)

    timestamps()
  end
end
