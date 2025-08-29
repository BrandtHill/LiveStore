defmodule LiveStore.Config do
  @table :live_store_config
  @filename ~c"live_store_config.tab"

  require Logger

  def init_table do
    case :ets.file2tab(@filename) do
      {:error, {:read_error, {:file_error, _file, :enoent}}} ->
        Logger.info("Config file for ETS table doesn't exist. Creating new table.")
        :ets.new(@table, [:named_table, :public, :set])

      {:error, {:read_error, {:file_error, _file, file_error}}} ->
        Logger.error(
          "Got #{file_error} initializing Config ETS table from file. Creating new table."
        )

        :ets.new(@table, [:named_table, :public, :set])

      {:error, :cannot_create_table} ->
        Logger.error("Config ETS table already exists.")

      {:ok, @table} ->
        Logger.info("Config ETS table successfully read from file.")
    end
  end

  defp sync_table do
    :ets.tab2file(@table, @filename)
  end

  defp get(key, default) do
    :ets.lookup(@table, key)[key] || default
  end

  defp set(key, value) do
    :ets.insert(@table, {key, value})
    sync_table()
  end

  defp delete(key) do
    :ets.delete(@table, key)
    sync_table()
  end

  @config_items_with_defaults [
    store_name: "LiveStore",
    store_subtitle: "An open source Phoenix LiveView e-commerce store",
    store_email: "contact@example.com",
    shipping_cost: 500,
    background_image:
      "https://images.unsplash.com/photo-1483985988355-763728e1935b?ixlib=rb-4.0.3&auto=format&fit=crop&w=3540&q=80"
  ]

  for {key, default} <- @config_items_with_defaults do
    def unquote(key)(), do: get(unquote(key), unquote(default))
    def unquote(key)(nil), do: delete(unquote(key))
    def unquote(key)(value), do: set(unquote(key), value)
  end

  def get_all_for_form do
    defaults = Map.new(@config_items_with_defaults)
    config = Map.new(:ets.tab2list(@table))

    defaults
    |> Map.merge(config)
    |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)
  end

  def get_defaults do
    Map.new(@config_items_with_defaults)
  end
end
