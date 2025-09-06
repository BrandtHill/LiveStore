defmodule LiveStore.Accounts.ContactForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias LiveStore.Accounts.User

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "contact_forms" do
    field :content, :string
    field :opened, :boolean, default: false
    belongs_to :user, User
    timestamps()
  end

  @fields [:content, :user_id, :opened]

  def changeset(contact_form \\ %__MODULE__{}, params) do
    contact_form
    |> cast(params, @fields)
    |> validate_length(:content, min: 2, max: 1000)
    |> validate_required(@fields)
    |> foreign_key_constraint(:user_id)
  end
end
