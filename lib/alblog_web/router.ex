defmodule AlblogWeb.Router do
  use AlblogWeb, :router

  import AlblogWeb.UserAuth
  # Import is still correctly at the top
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AlblogWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :admin_only do
    plug :browser

    plug :require_authenticated_user

    plug AlblogWeb.Plugs.RequireAdmin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AlblogWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # ======================================================
  # Dashboard Definition (Defined only once)
  # ======================================================

  # In Prod (MIX_ENV=prod), we want the admin protection.
  # In Dev (MIX_ENV=dev), we often want the protection too,
  # or sometimes a simpler pipe if you prefer.
  # We will use :admin_only as the default for the main /dashboard route.
  scope "/" do
    # Apply protection to the main dashboard route
    pipe_through :admin_only

    live_dashboard "/dashboard", metrics: AlblogWeb.Telemetry
  end

  # ======================================================
  # DEV Routes (Only for Swoosh Mailbox Preview)
  # ======================================================

  if Application.compile_env(:alblog, :dev_routes) do
    # Note: We do NOT define live_dashboard here anymore, only forward/mailbox.
    # The /dashboard is handled above.
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AlblogWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{AlblogWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/articles/new", ArticleLive.Form, :new
      live "/articles/:id/edit", ArticleLive.Form, :edit
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", AlblogWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{AlblogWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/users/reset-password", UserLive.ForgotPassword, :new
      live "/users/reset-password/:token", UserLive.ResetPassword, :edit
      live "/articles", ArticleLive.Index, :index
      live "/articles/:id", ArticleLive.ShowPublic, :show
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
