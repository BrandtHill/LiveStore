defmodule LiveStore.Config do
  @table :live_store_config
  @filename ~c"live_store_config.tab"

  require Logger

  import Ecto.Changeset

  def init_table do
    case :ets.file2tab(@filename) do
      {:error, {:read_error, {:file_error, _file, :enoent}}} ->
        Logger.info("Config file for ETS table doesn't exist. Creating new table.")
        :ets.new(@table, [:named_table, :public, :set])

      {:error, {:read_error, {:file_error, _file, error}}} ->
        Logger.error("Got #{error} initializing Config ETS table from file. Creating new table.")
        :ets.new(@table, [:named_table, :public, :set])

      {:error, :cannot_create_table} ->
        Logger.error("Config ETS table already exists.")

      {:ok, @table} ->
        Logger.info("Config ETS table successfully read from file.")
    end
  end

  defp get(key, default) do
    :ets.lookup(@table, key)[key] || default
  end

  defp bulk_insert(values) do
    :ets.insert(@table, values)
    :ets.tab2file(@table, @filename)
  end

  # I could have created an Ecto embedded_schema, but I preferred generating functions for each field
  # at compile time. Making this module a struct would also make it seem like %Config{} structs could
  # created and passed around, but this is meant be a type of "singleton" pattern to borrow a term
  # from a lesser paradigm. Did you know you could use Ecto Changesets with a tuple of data map
  # and corresponding type map?

  @config_defaults %{
    store_name: "LiveStore",
    store_subtitle: "An open source Phoenix LiveView e-commerce store",
    store_email: "contact@example.com",
    shipping_cost: 500,
    favicon: "/favicon.ico",
    background_image:
      "https://images.unsplash.com/photo-1483985988355-763728e1935b?ixlib=rb-4.0.3&auto=format&fit=crop&w=3540&q=80"
  }

  @config_types Map.new(@config_defaults, fn
                  {key, value} when is_integer(value) -> {key, :integer}
                  {key, _value} -> {key, :string}
                end)

  @config_keys Map.keys(@config_defaults)

  for {key, default} <- @config_defaults do
    def unquote(key)(), do: get(unquote(key), unquote(default))
  end

  def config, do: Map.new(:ets.tab2list(@table))
  def defaults, do: @config_defaults

  def changeset(config, params \\ %{}) do
    {config, @config_types}
    |> cast(params, @config_keys)
    |> validate_number(:shipping_cost, greater_than_or_equal_to: 0)
  end

  def update(changeset) do
    changeset.changes
    |> Enum.to_list()
    |> bulk_insert()
  end
end
