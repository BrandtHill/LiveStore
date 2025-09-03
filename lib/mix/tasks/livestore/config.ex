defmodule Mix.Tasks.Livestore.Config do
  @moduledoc """
  Read or set store settings from the command line.
  All these settings can be changed from the app.
  """

  use Mix.Task

  alias LiveStore.ReleaseTasks

  def run(args) do
    Mix.Task.run("app.config")

    Application.ensure_all_started(:live_store)

    case args do
      [key, value] ->
        ReleaseTasks.change_config(key, value)

      [] ->
        ReleaseTasks.config()

      _ ->
        IO.puts("""
        Run `mix livestore.config` to get current values
        Run `mix livestore.config "key" "value" to set a value`
        """)
    end
  end
end
