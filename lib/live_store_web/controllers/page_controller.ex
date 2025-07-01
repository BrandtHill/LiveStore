defmodule LiveStoreWeb.PageController do
  use LiveStoreWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
