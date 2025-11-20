defmodule AlblogWeb.UserLive.ResetPassword do
  use AlblogWeb, :live_view

  alias Alblog.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>Reset password</p>
            <:subtitle>
              Enter your new password below.
            </:subtitle>
          </.header>
        </div>

        <.form
          :let={f}
          for={@form}
          id="reset_password_form"
          phx-submit="reset_password"
          phx-change="validate"
        >
          <.input
            field={f[:password]}
            type="password"
            label="New password"
            autocomplete="new-password"
            required
            phx-mounted={JS.focus()}
          />
          <.input
            field={f[:password_confirmation]}
            type="password"
            label="Confirm new password"
            autocomplete="new-password"
            required
          />
          <.button class="btn btn-primary w-full mt-4">
            Reset password <span aria-hidden="true">→</span>
          </.button>
        </.form>

        <div class="text-center text-sm mt-4">
          <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
            Back to log in
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    socket =
      case params do
        %{"token" => token} ->
          if user = Accounts.get_user_by_reset_password_token(token) do
            socket
            |> assign(:user, user)
            |> assign(:token, token)
          else
            socket
            |> put_flash(:error, "Reset password link is invalid or it has expired.")
            |> push_navigate(to: ~p"/users/reset-password")
          end

        _ ->
          socket
          |> assign(:user, nil)
          |> assign(:token, nil)
      end

    form = to_form(%{}, as: "user")
    {:ok, assign(socket, form: form)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    form =
      socket.assigns.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully. Please log in with your new password.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
