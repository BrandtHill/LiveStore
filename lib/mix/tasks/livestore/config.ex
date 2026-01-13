defmodule Mix.Tasks.Livestore.Config do
  @moduledoc """
  Read or set store settings from the command line.
  All these settings can be changed from the app.
  """

  use Mix.Task

  alias LiveStore.ReleaseTasks

  def run(args) do
    Mix.Task.run("app.config")

    case args do
      [key, value] ->
        ReleaseTasks.change_config(key, value)

      [key, subkey, value] ->
        ReleaseTasks.change_config(key, subkey, value)

      [] ->
        ReleaseTasks.config()

      _ ->
        IO.puts("""
        Run `mix livestore.config` to get current values
        Run `mix livestore.config "key" "value"` to set a value
        Run `mix livestore.config "key" "subkey" "value"` to set nested map values (empty string value for delete)
        """)
    end
  end
end
