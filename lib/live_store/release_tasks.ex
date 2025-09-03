defmodule LiveStore.ReleaseTasks do
  @moduledoc """
  ReleaseTasks that can run from production.
  """

  alias LiveStore.Accounts
  alias LiveStore.Accounts.User

  @doc """
  Make a LiveStore account an admin given an email.
  """
  def make_admin(email) when is_binary(email), do: make_admin([email])

  def make_admin(args) when is_list(args) do
    Application.ensure_all_started(:live_store)

    with [email | _] <- args,
         %User{} = user <- assert_account(email),
         {:ok, user} <- Accounts.make_user_admin(user) do
      IO.puts("#{user.email} is now an admin.")
    else
      error ->
        IO.puts("""
          You messed something up. #{inspect(error)}
          Run `mix livestore.admin "myname@example.com"` if this was a mix task.
          Call `LiveStore.ReleaseTasks.make_admin("myname@example.com")` if this was an eval call.
        """)
    end
  end

  defp assert_account(email) do
    with nil <- Accounts.get_user_by_email(email),
         {:error, changeset} <- Accounts.register_user(%{email: email}) do
      changeset.errors
    else
      %User{} = user -> user
      {:ok, %User{} = user} -> user
    end
  end
end
