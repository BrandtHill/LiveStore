defmodule LiveStoreWeb.Emails do
  use LiveStoreWeb, :html

  embed_templates "emails/*"

  def heex_to_html(template) do
    template
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
