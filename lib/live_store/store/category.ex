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
    |> validate_format(:path, ~r/^(?!\w+\.(edit|new)$).*/, message: "is unreachable")
    |> prepare_changes(fn
      %{action: :delete} = c -> c |> reparent_orphans()
      %{action: :update} = c -> c |> update_children() |> backfill_ancestors()
      %{action: :insert} = c -> c |> backfill_ancestors()
      c -> c
    end)
    |> unsafe_validate_unique(:path, LiveStore.Repo)
    |> unique_constraint(:path)
  end

  def path_from_parent(%__MODULE__{path: path} = _parent, name) do
    path_from_parent(path, name)
  end

  def path_from_parent(path, name) when is_binary(path) do
    path <> "." <> label_from_name(name)
  end

  def path_from_parent(nil, name) do
    label_from_name(name)
  end

  def path_from_self(%__MODULE__{path: old_path} = _self, name) do
    path_from_self(old_path, name)
  end

  def path_from_self(path, name) when is_binary(path) do
    label = label_from_name(name)

    path
    |> String.split(".")
    |> List.replace_at(-1, label)
    |> Enum.join(".")
  end

  def path_from_self(nil, name) do
    label_from_name(name)
  end

  def label_from_name(name) do
    name
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
    |> String.replace(~r/[^a-z0-9_]/, "")
    |> String.replace(~r/_+/, "_")
    |> String.trim("_")
  end

  defp reparent_orphans(%{repo: repo, data: %{path: path}} = changeset) do
    temp_rename_path(changeset)

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

  defp temp_rename_path(%{data: %{path: path}, repo: repo}) when is_binary(path),
    do: repo.update_all(from(__MODULE__, where: [path: ^path]), set: [path: "TEMP." <> path])

  defp temp_rename_path(_), do: :noop

  defp backfill_ancestors(%{repo: repo, changes: %{path: path}} = changeset) do
    temp_rename_path(changeset)

    closest_level =
      repo.one(
        from c in __MODULE__,
          where: fragment("? @> ?", c.path, ^path) and c.path != ^path,
          select: coalesce(max(fragment("nlevel(?)", c.path)), 0)
      )

    ghosts =
      repo.all(
        from level in fragment(
               "generate_series(? + 1, nlevel(?) - 1)",
               ^closest_level,
               ^path
             ),
             select: %{
               path: fragment("subpath(?, 0, ?)", ^path, level),
               name:
                 fragment(
                   "initcap(regexp_replace(subpath(?, ? - 1, 1)::text, '_+', ' ', 'g'))",
                   ^path,
                   level
                 )
             }
      )

    entries =
      Enum.map(
        ghosts,
        &Map.merge(&1, %{
          inserted_at: {:placeholder, :timestamp},
          updated_at: {:placeholder, :timestamp},
          id: UUIDv7.generate()
        })
      )

    repo.insert_all(__MODULE__, entries, placeholders: %{timestamp: DateTime.utc_now()})

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
