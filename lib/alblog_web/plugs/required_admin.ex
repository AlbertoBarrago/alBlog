defmodule AlblogWeb.Plugs.RequireAdmin do
  @moduledoc """
  A Plug that ensures the currently authenticated user has administrative
  privileges before allowing access to the route.
  """
  import Plug.Conn
  import Phoenix.Controller
  alias Alblog.Accounts.User

  @doc "Initializes the plug (required by the Plug specification)."
  def init(opts), do: opts

  @doc "Checks the user's admin status and redirects if unauthorized."
  def call(conn, _opts) do
    current_user =
      conn.assigns[:current_user] ||
        (conn.assigns[:current_scope] && conn.assigns[:current_scope].user)

    if current_user && User.is_admin?(current_user) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to access this section.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
