defmodule AlblogWeb.ArticleLive.ShowPublic do
  use AlblogWeb, :live_view

  alias Alblog.Blog
  alias Alblog.Blog.Comment
  alias AlblogWeb.Presence

  @topic "article_presence"

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      # Subscribe to the topic
      Phoenix.PubSub.subscribe(Alblog.PubSub, "#{@topic}:#{id}")

      # Subscribe to comment updates
      Blog.subscribe_comments(id)

      # Subscribe to article updates if user is logged in
      if socket.assigns[:current_scope] do
        Blog.subscribe_articles(socket.assigns.current_scope)
      end

      # Track presence
      {:ok, _} =
        Presence.track(self(), "#{@topic}:#{id}", socket.id, %{
          online_at: inspect(System.system_time(:second))
        })

      # Record article visit for daily digest
      Blog.record_article_visit(String.to_integer(id))
    end

    article = Blog.get_article!(id)
    comments = Blog.list_comments(id)

    {:ok,
     socket
     |> assign(:article, article)
     |> assign(:reader_count, get_reader_count(id))
     |> assign(:page_title, article.title)
     |> assign(:comment_form, to_form(Blog.change_comment(%Comment{})))
     |> stream(:comments, comments)}
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

  def handle_event("validate_comment", %{"comment" => comment_params}, socket) do
    changeset =
      %Comment{}
      |> Blog.change_comment(comment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :comment_form, to_form(changeset))}
  end

  def handle_event("save_comment", %{"comment" => comment_params}, socket) do
    case socket.assigns[:current_scope] do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to comment.")}

      scope ->
        case Blog.create_comment(scope, socket.assigns.article, comment_params) do
          {:ok, _comment} ->
            {:noreply,
             socket
             |> assign(:comment_form, to_form(Blog.change_comment(%Comment{})))
             |> put_flash(:info, "Comment added successfully!")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :comment_form, to_form(changeset))}
        end
    end
  end

  def handle_event("delete_comment", %{"id" => id}, socket) do
    comment = Blog.get_comment!(id)

    case Blog.delete_comment(socket.assigns.current_scope, comment) do
      {:ok, _comment} ->
        {:noreply, put_flash(socket, :info, "Comment deleted.")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You can only delete your own comments.")}
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

  def handle_info({:comment_created, comment}, socket) do
    {:noreply, stream_insert(socket, :comments, comment)}
  end

  def handle_info({:comment_deleted, comment}, socket) do
    {:noreply, stream_delete(socket, :comments, comment)}
  end

  # Catch-all for unexpected messages (e.g., from async tasks in tests)
  def handle_info(_msg, socket) do
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
              <.link navigate={~p"/articles?tag=#{tag}"}>
                <span class={"badge badge-sm #{AlblogWeb.TagHelper.tag_color(tag)} hover:opacity-80 transition cursor-pointer"}>
                  {tag}
                </span>
              </.link>
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
          <.link navigate={~p"/articles"} class="btn btn-outline btn-sm">
            Read more articles
          </.link>
        </div>
      </div>

      <div class="mt-12 pt-8 border-t border-base-300">
        <h2 class="text-2xl font-bold text-base-content mb-6 flex items-center gap-2">
          <.icon name="hero-chat-bubble-left-right" class="w-6 h-6" /> Comments
        </h2>

        <%= if Map.get(assigns, :current_scope) do %>
          <.form
            for={@comment_form}
            id="comment-form"
            phx-change="validate_comment"
            phx-submit="save_comment"
            class="mb-8"
          >
            <div class="flex flex-col gap-3">
              <.input
                field={@comment_form[:body]}
                type="textarea"
                placeholder="Write a comment..."
                rows="3"
                class="textarea textarea-bordered w-full bg-base-200 focus:bg-base-100 transition"
              />
              <div class="flex justify-end">
                <button type="submit" class="btn btn-primary btn-sm">
                  <.icon name="hero-paper-airplane" class="w-4 h-4" /> Post Comment
                </button>
              </div>
            </div>
          </.form>
        <% else %>
          <div class="mb-8 p-4 bg-base-200 rounded-lg text-center">
            <p class="text-base-content/70">
              <.link navigate={~p"/users/log-in"} class="link link-primary font-medium">
                Log in
              </.link>
              to join the discussion.
            </p>
          </div>
        <% end %>

        <div id="comments" phx-update="stream" class="space-y-4">
          <div id="comments-empty" class="hidden only:block text-center py-8 text-base-content/50">
            No comments yet. Be the first to share your thoughts!
          </div>
          <div
            :for={{dom_id, comment} <- @streams.comments}
            id={dom_id}
            class="bg-base-200 rounded-lg p-4 transition hover:bg-base-200/80"
          >
            <div class="flex justify-between items-start gap-4">
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 mb-2">
                  <span class="font-semibold text-base-content">{comment.user.username}</span>
                  <span class="text-xs text-base-content/50">
                    {Calendar.strftime(comment.inserted_at, "%d %b %Y at %H:%M")}
                  </span>
                </div>
                <p class="text-base-content/80 whitespace-pre-wrap break-words">{comment.body}</p>
              </div>
              <%= if Map.get(assigns, :current_scope) && (comment.user_id == @current_scope.user.id || @current_scope.user.role == "admin") do %>
                <button
                  phx-click="delete_comment"
                  phx-value-id={comment.id}
                  data-confirm="Delete this comment?"
                  class="btn btn-ghost btn-xs text-error hover:bg-error/10 flex-shrink-0"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    <Layouts.flash_group flash={@flash} />
    """
  end
end
