defmodule SimpleCrudWeb.ArticleLive.Form do
  use SimpleCrudWeb, :live_view

  alias SimpleCrud.Blog
  alias SimpleCrud.Blog.Article
  
  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage article records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="article-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="textarea" label="Title" />
        <.input field={@form[:slug]} type="textarea" label="Slug" />
        <.input field={@form[:content]} type="textarea" label="Content" />
        <.input field={@form[:published_at]} type="datetime-local" label="Published at" />
        <.input field={@form[:category]} type="text" label="Category" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Article</.button>
          <.button navigate={return_path(@current_scope, @return_to, @article)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    article = Blog.get_article!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Article")
    |> assign(:article, article)
    |> assign(:form, to_form(Blog.change_article(socket.assigns.current_scope, article)))
  end

  defp apply_action(socket, :new, _params) do
    article = %Article{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Article")
    |> assign(:article, article)
    |> assign(:form, to_form(Blog.change_article(socket.assigns.current_scope, article)))
  end

  @impl true
  def handle_event("validate", %{"article" => article_params}, socket) do
    changeset = Blog.change_article(socket.assigns.current_scope, socket.assigns.article, article_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"article" => article_params}, socket) do
    save_article(socket, socket.assigns.live_action, article_params)
  end

  defp save_article(socket, :edit, article_params) do
    case Blog.update_article(socket.assigns.current_scope, socket.assigns.article, article_params) do
      {:ok, article} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, article)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_article(socket, :new, article_params) do
    case Blog.create_article(socket.assigns.current_scope, article_params) do
      {:ok, article} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, article)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _article), do: ~p"/articles"
  defp return_path(_scope, "show", article), do: ~p"/articles/#{article}"
end
