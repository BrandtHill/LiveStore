defmodule Mix.Tasks.Livestore.Admin do
  @moduledoc """
  Make a LiveStore account an admin given an email.
  """

  use Mix.Task

  alias LiveStore.ReleaseTasks

  def run(args) do
    Mix.Task.run("app.config")

    ReleaseTasks.make_admin(args)
  end
end
