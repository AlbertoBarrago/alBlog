defmodule AlblogWeb.Router do
  use AlblogWeb, :router
  import AlblogWeb.UserAuth
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

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_auth do
    plug :require_authenticated_user
  end

  pipeline :admin do
    plug AlblogWeb.Plugs.RequireAdmin
  end

  scope "/", AlblogWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  # ======================================================
  # Dashboard Definition
  # ======================================================
  scope "/" do
    pipe_through [:browser, :require_auth, :admin]
    live_dashboard "/dashboard", metrics: AlblogWeb.Telemetry
  end

  # ======================================================
  # DEV Routes (Only for Swoosh Mailbox Preview)
  # ======================================================
  if Application.compile_env(:alblog, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes
  scope "/", AlblogWeb do
    pipe_through [:browser, :require_auth]

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
