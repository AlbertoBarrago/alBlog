defmodule AlblogWeb.ArticleLive.ShowPublic do
  use AlblogWeb, :live_view

  alias Alblog.Blog
  alias AlblogWeb.Presence

  @topic "article_presence"

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      # Subscribe to the topic
      Phoenix.PubSub.subscribe(Alblog.PubSub, "#{@topic}:#{id}")

      # Subscribe to article updates if user is logged in
      if socket.assigns[:current_scope] do
        Blog.subscribe_articles(socket.assigns.current_scope)
      end

      # Track presence
      {:ok, _} =
        Presence.track(self(), "#{@topic}:#{id}", socket.id, %{
          online_at: inspect(System.system_time(:second))
        })
    end

    article = Blog.get_article!(id)

    {:ok,
     socket
     |> assign(:article, article)
     |> assign(:reader_count, get_reader_count(id))
     |> assign(:page_title, article.title)}
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
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :reader_count, get_reader_count(socket.assigns.article.id))}
  end

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

  defp get_reader_count(article_id) do
    Presence.list("#{@topic}:#{article_id}")
    |> map_size()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div class="mb-8 flex justify-between items-center">
        <.link
          navigate={~p"/"}
          class="text-sm font-medium text-base-content/60 hover:text-primary transition flex items-center gap-1"
        >
          <.icon name="hero-arrow-left-mini" class="w-4 h-4" /> Back to Home
        </.link>

        <div class="flex items-center gap-3">
          <div class="flex items-center gap-2 text-sm font-medium text-base-content/70 bg-base-200 px-3 py-1.5 rounded-full">
            <span class="relative flex h-3 w-3">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opacity-75">
              </span>
              <span class="relative inline-flex rounded-full h-3 w-3 bg-success"></span>
            </span>
            <span>{@reader_count} reading now</span>
          </div>
        </div>
      </div>

      <article class="prose prose-lg prose-slate dark:prose-invert mx-auto">
        <div class="flex items-center gap-3 text-sm text-base-content/60 mb-4">
          <time datetime={@article.published_at}>
            {Calendar.strftime(@article.published_at || DateTime.utc_now(), "%d-%m-%Y %H:%M")}
          </time>
          <div class="flex gap-1.5">
            <%= for tag <- @article.category do %>
              <span class={"badge badge-sm #{AlblogWeb.TagHelper.tag_color(tag)}"}>
                {tag}
              </span>
            <% end %>
          </div>
        </div>

        <h1 class="text-4xl font-extrabold tracking-tight text-base-content sm:text-5xl mb-4">
          {@article.title}
        </h1>

        <div class="flex items-center gap-3 text-sm text-base-content/30">
          <span class="font-medium">
            Written by:
            <span class="font-medium text-secondary">
              {@article.user.username}
            </span>
          </span>
        </div>

        <div class="mt-4 text-base-content/80 leading-relaxed prose prose-lg max-w-none">
          {AlblogWeb.MarkdownHelper.to_html(@article.content) |> Phoenix.HTML.raw()}
        </div>
      </article>

      <div class="mt-16 pt-8 border-t border-base-300">
        <div class="flex justify-between items-center">
          <div class="text-sm text-base-content/60 flex items-center gap-3">
            Thanks for reading!
            <%= if Map.get(assigns, :current_scope) && @current_scope.user.role == "admin" && @article.user_id == @current_scope.user.id do %>
              <div class="flex items-center gap-2 ml-4 border-l border-base-300 pl-4">
                <.link
                  navigate={~p"/articles/#{@article}/edit"}
                  class="btn btn-sm btn-ghost text-primary hover:bg-primary/10"
                >
                  <.icon name="hero-pencil-square" /> Edit
                </.link>
                <button
                  phx-click="delete"
                  data-confirm="Are you sure you want to delete this article?"
                  class="btn btn-sm btn-ghost text-error hover:bg-error/10"
                >
                  <.icon name="hero-trash" /> Delete
                </button>
              </div>
            <% end %>
          </div>
          <.link navigate={~p"/"} class="btn btn-outline btn-sm">
            Read more articles
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
