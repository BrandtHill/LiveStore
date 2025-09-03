defmodule LiveStore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    File.mkdir_p!(LiveStore.Uploads.uploads_dir())
    LiveStore.Config.init_table()

    children = [
      LiveStoreWeb.Telemetry,
      LiveStore.Repo,
      {DNSCluster, query: Application.get_env(:live_store, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LiveStore.PubSub},
      # Start a worker by calling: LiveStore.Worker.start_link(arg)
      # {LiveStore.Worker, arg},
      # Start to serve requests, typically the last entry
      LiveStoreWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveStore.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveStoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
