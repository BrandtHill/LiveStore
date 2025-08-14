defmodule LiveStoreWeb.Router do
  use LiveStoreWeb, :router

  import LiveStoreWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveStoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :fetch_cart
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveStoreWeb do
    pipe_through [:browser]

    get "/", PageController, :home

    live_session :shop, on_mount: [{LiveStoreWeb.UserAuth, :mount_current_user}] do
      live "/products", ShopLive.Index, :index
      live "/products/:slug", ShopLive.ProductPage
      live "/cart", ShopLive.Cart, :show
      live "/cart/checkout", ShopLive.Cart, :checkout
      live "/order/success", OrderLive.Success
    end

    scope "/admin", Admin do
      live_session :product_admin, on_mount: [{LiveStoreWeb.UserAuth, :require_admin}] do
        live "/products", ProductLive.Index, :index
        live "/products/new", ProductLive.Form, :new
        live "/products/:id/edit", ProductLive.Form, :edit

        live "/products/:id", ProductLive.Show, :show

        live "/products/:id/variants", VariantLive.Index, :index
        live "/products/:id/variants/new", VariantLive.Form, :new
        live "/products/:id/variants/:variant_id/edit", VariantLive.Form, :edit
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveStoreWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:live_store, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LiveStoreWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", LiveStoreWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{LiveStoreWeb.UserAuth, :require_authenticated}] do
      live "/account/settings", UserLive.Settings, :edit
      live "/account/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end
  end

  scope "/", LiveStoreWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{LiveStoreWeb.UserAuth, :mount_current_user}] do
      live "/account/login", UserLive.Login, :new
      live "/account/login/:token", UserLive.Confirmation, :new
    end

    post "/account/login", UserSessionController, :create
    delete "/account/logout", UserSessionController, :delete
  end
end
