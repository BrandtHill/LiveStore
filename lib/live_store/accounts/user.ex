defmodule LiveStore.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "users" do
    field :email, :string
    field :confirmed_at, :utc_datetime_usec
    field :authenticated_at, :utc_datetime_usec, virtual: true
    field :admin, :boolean, default: false
    field :stripe_id, :string

    timestamps()
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, LiveStore.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    change(user, confirmed_at: DateTime.utc_now())
  end

  def admin_changeset(%__MODULE__{} = user, is_admin? \\ true) do
    change(user, admin: is_admin?)
  end

  def stripe_changeset(%__MODULE__{} = user, stripe_customer_id)
      when is_binary(stripe_customer_id) do
    change(user, stripe_id: stripe_customer_id)
  end

  def stripe_changeset(changeset, params) do
    cast(changeset, params, [:stripe_id])
  end
end
