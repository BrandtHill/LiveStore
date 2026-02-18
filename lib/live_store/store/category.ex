defmodule LiveStore.Store.Category do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias LiveStore.Store.Product

  @primary_key {:id, UUIDv7, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts type: :utc_datetime_usec

  schema "categories" do
    field :name, :string
    field :path, :string
    field :leaf?, :boolean, virtual: true

    has_many :products, Product

    timestamps()
  end

  @required_fields [:name, :path]

  def changeset(category \\ %__MODULE__{}, params) do
    category
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, max: 255)
    |> validate_format(:path, ~r/^([a-z0-9_]+\.)*[a-z0-9_]+$/)
    |> prepare_changes(fn
      %{action: :delete} = c -> reparent_children(c)
      %{action: :update} = c -> update_children(c)
      c -> c
    end)
    |> unsafe_validate_unique(:path, LiveStore.Repo)
    |> unique_constraint(:path)
  end

  def path_from_parent(%__MODULE__{path: path} = _parent, name) do
    path <> "." <> label_from_name(name)
  end

  def path_from_parent(parent, name) when is_binary(parent) do
    parent <> "." <> label_from_name(name)
  end

  def path_from_parent(nil, name) do
    label_from_name(name)
  end

  def label_from_name(name) do
    name
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
    |> String.replace(~r/[^a-z0-9_]/, "")
    |> String.replace(~r/_+/, "_")
    |> String.trim("_")
  end

  defp reparent_children(%{repo: repo, data: %{path: path}} = changeset) do
    repo.update_all(
      from(c in __MODULE__,
        where: fragment("? <@ ?", c.path, ^path) and c.path != ^path,
        update: [
          set: [
            path:
              fragment(
                "subpath(?, 0, nlevel(?) - 1) || subpath(?, nlevel(?))",
                c.path,
                ^path,
                c.path,
                ^path
              )
          ]
        ]
      ),
      set: [updated_at: DateTime.utc_now()]
    )

    changeset
  end

  defp update_children(
         %{repo: repo, data: %{path: old_path}, changes: %{path: new_path}} = changeset
       ) do
    repo.update_all(
      from(c in __MODULE__,
        where: fragment("? <@ ?", c.path, ^old_path) and c.path != ^old_path,
        update: [
          set: [
            path: fragment("?::ltree || subpath(?, nlevel(?))", ^new_path, c.path, ^old_path)
          ]
        ]
      ),
      set: [updated_at: DateTime.utc_now()]
    )

    changeset
  end

  defp update_children(changeset), do: changeset
end
