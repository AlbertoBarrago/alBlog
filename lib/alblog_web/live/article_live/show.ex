defmodule AlblogWeb.ArticleLive.Show do
  use AlblogWeb, :live_view

  alias Alblog.Blog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Article {@article.id}
        <:subtitle>This is a article record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/articles"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <%= if @current_scope && @current_scope.role == :admin do %>
            <.button variant="primary" navigate={~p"/articles/#{@article}/edit?return_to=show"}>
              <.icon name="hero-pencil-square" /> Edit article
            </.button>
            <.button
              phx-click="delete"
              data-confirm="Are you sure you want to delete this article?"
              class="btn-error"
            >
              <.icon name="hero-trash" /> Delete
            </.button>
          <% end %>
        </:actions>
      </.header>

      <.list>
        <:item title="Title">{@article.title}</:item>
        <:item title="Slug">{@article.slug}</:item>
        <:item title="Content">
          <div class="prose prose-lg max-w-none text-base-content leading-relaxed">
            {AlblogWeb.MarkdownHelper.to_html(@article.content) |> Phoenix.HTML.raw()}
          </div>
        </:item>
        <:item title="Published at">{@article.published_at}</:item>
        <:item title="Category">
          <div class="flex flex-wrap gap-2">
            <%= for tag <- @article.category do %>
              <span class={"badge badge-sm #{AlblogWeb.TagHelper.tag_color(tag)}"}>
                {tag}
              </span>
            <% end %>
          </div>
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Blog.subscribe_articles(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Article")
     |> assign(:article, Blog.get_article!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    case Blog.delete_article(socket.assigns.current_scope, socket.assigns.article) do
      {:ok, _article} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article deleted successfully.")
         |> push_navigate(to: ~p"/articles")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete article.")}
    end
  end

  @impl true
  def handle_info(
        {:updated, %Alblog.Blog.Article{id: id} = article},
        %{assigns: %{article: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :article, article)}
  end

  def handle_info(
        {:deleted, %Alblog.Blog.Article{id: id}},
        %{assigns: %{article: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current article was deleted.")
     |> push_navigate(to: ~p"/articles")}
  end

  def handle_info({type, %Alblog.Blog.Article{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
