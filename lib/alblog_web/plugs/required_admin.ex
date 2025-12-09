defmodule AlblogWeb.Plugs.RequireAdmin do
  @moduledoc """
  A Plug that ensures the currently authenticated user has administrative
  privileges before allowing access to the route.

  It relies on the presence of `:current_user` in `conn.assigns`, which is
  set by a preceding authentication Plug.
  """
  import Plug.Conn
  import Phoenix.Controller

  @doc "Initializes the plug (required by the Plug specification)."
  def init(opts), do: opts

  @doc "Checks the user's admin status and redirects if unauthorized."
  def call(conn, _opts) do
    current_user = conn.assigns[:current_user]

    if current_user && Alblog.Accounts.User.is_admin?(current_user) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to access this section.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
