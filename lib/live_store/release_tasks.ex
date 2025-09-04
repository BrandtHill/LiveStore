defmodule LiveStore.ReleaseTasks do
  @moduledoc """
  ReleaseTasks that can run from production without Mix.
  """
  @app :live_store

  alias LiveStore.Accounts
  alias LiveStore.Accounts.User
  alias LiveStore.Accounts.UserToken
  alias LiveStore.Config
  alias LiveStore.Repo

  @doc """
  Make a LiveStore account an admin given an email.
  """
  def make_admin(email) when is_binary(email), do: make_admin([email])

  def make_admin(args) when is_list(args) do
    Application.ensure_all_started(@app)

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

  @doc """
  Generate a login URL for a user for before email is configured.
  """
  def login(email) when is_binary(email), do: login([email])

  def login(args) when is_list(args) do
    Application.ensure_all_started(@app)

    with [email | _] <- args,
         %User{} = user <- assert_account(email),
         {encoded_token, %UserToken{} = user_token} <- UserToken.build_email_token(user, "login"),
         {:ok, %UserToken{}} <- Repo.insert(user_token) do
      path = "/account/login/#{encoded_token}"

      IO.puts("""
      Go to this endpoint your website to login:

        #{path}

      For example, https://mylivestore.com#{path}
      """)
    else
      error ->
        IO.puts("""
          You messed something up. #{inspect(error)}
          Run `mix livestore.login "myname@example.com"` if this was a mix task.
          Call `LiveStore.ReleaseTasks.login("myname@example.com")` if this was an eval call.
        """)
    end
  end

  def config() do
    Application.ensure_all_started(@app)

    IO.puts("""
    Current config read from ETS:
    #{inspect(Config.config(), pretty: true)}

    Default values if no config or nil:
    #{inspect(Config.defaults(), pretty: true)}
    """)
  end

  def change_config(key, value) do
    Application.ensure_all_started(@app)

    case Config.config() |> Config.changeset(%{key => value}) do
      %Ecto.Changeset{valid?: true, changes: changes} = cs when map_size(changes) > 0 ->
        Config.update(cs)
        IO.puts("#{key} set successfully")

      %Ecto.Changeset{valid?: true} ->
        IO.puts("#{key} isn't a valid config option")

      %Ecto.Changeset{valid?: false} = cs ->
        IO.puts("You messed something up. #{inspect(cs.errors, pretty: true)}")
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

  ## DB Migration Release Tasks

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end
end
