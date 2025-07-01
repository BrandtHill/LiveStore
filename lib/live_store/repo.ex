defmodule LiveStore.Repo do
  use Ecto.Repo,
    otp_app: :live_store,
    adapter: Ecto.Adapters.Postgres
end
