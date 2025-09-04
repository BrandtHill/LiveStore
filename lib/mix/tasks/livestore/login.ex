defmodule Mix.Tasks.Livestore.Login do
  @moduledoc """
  Generate a login URL for a user for before email is configured.
  """

  use Mix.Task

  alias LiveStore.ReleaseTasks

  def run(args) do
    Mix.Task.run("app.config")

    ReleaseTasks.login(args)
  end
end
