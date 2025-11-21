defmodule AlblogWeb.ArticleLive.Index do
  use AlblogWeb, :live_view

  alias Alblog.Blog
  alias Alblog.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-3xl font-bold text-primary">Articles</h1>
          <%= if @current_scope && @current_scope.user && Accounts.User.is_admin?(@current_scope.user) do %>
            <.link href={~p"/articles/new"}>
              <.button variant="primary">New Article</.button>
            </.link>
          <% end %>
        </div>
      </.header>

      <%= if Enum.empty?(@streams.articles.inserts) do %>
        <div class="col-span-full flex flex-col items-center justify-center py-16 px-4">
          <div class="text-center max-w-md">
            <svg
              class="mx-auto h-24 w-24 text-base-content/20 mb-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              aria-hidden="true"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="1.5"
                d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"
              />
            </svg>
            <h3 class="text-2xl font-semibold text-base-content mb-2">No articles yet</h3>
            <p class="text-base-content/60 mb-8">
              Get started by creating your first article. Share your thoughts, ideas, and stories with the world!
            </p>
            <.button variant="primary" navigate={~p"/articles/new"} class="inline-flex items-center">
              <.icon name="hero-plus" class="mr-2" /> Create your first article
            </.button>
          </div>
        </div>
      <% else %>
        <div id="articles" phx-update="stream" class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div
            :for={{id, article} <- @streams.articles}
            id={id}
            class="bg-base-100 overflow-hidden shadow-lg rounded-xl flex flex-col transition duration-300 hover:shadow-2xl"
          >
            <div class="px-6 py-8 flex-grow">
              <div class="mb-4">
                <h3 class="text-2xl font-bold text-base-content leading-tight mb-2">
                  <.link navigate={~p"/articles/#{article}"} class="hover:text-primary transition">
                    {article.title}
                  </.link>
                </h3>
                <div class="flex flex-wrap gap-2">
                  <%= for tag <- article.category || [] do %>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary">
                      {tag}
                    </span>
                  <% end %>
                </div>
              </div>
              <div class="mb-4 text-sm text-base-content/60 flex items-center">
                <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
                {Calendar.strftime(article.published_at || DateTime.utc_now(), "%d-%m-%Y %H:%M")}
                <span class="mx-2">•</span>
                <span>By {article.user.username}</span>
              </div>
              <div class="text-base-content/80 leading-relaxed line-clamp-4 prose prose-sm max-w-none">
                {Earmark.as_html!(article.content || "") |> Phoenix.HTML.raw()}
              </div>
            </div>
            <div class="bg-base-200 px-6 py-4 flex justify-between items-center border-t border-base-300">
              <.link
                navigate={~p"/articles/#{article}"}
                class="text-base font-semibold text-primary hover:text-primary-focus transition flex items-center"
              >
                Read full article <span aria-hidden="true" class="ml-1">&rarr;</span>
              </.link>
              <%= if @current_scope && @current_scope.user && Alblog.Accounts.User.is_admin?(@current_scope.user) do %>
                <div class="flex space-x-4">
                  <.link
                    navigate={~p"/articles/#{article}/edit"}
                    class="text-sm font-medium text-base-content/60 hover:text-base-content transition"
                  >
                    Edit
                  </.link>
                  <.link
                    phx-click={JS.push("delete", value: %{id: article.id}) |> hide("##{id}")}
                    data-confirm="Are you sure?"
                    class="text-sm font-medium text-error hover:text-error-content transition"
                  >
                    Delete
                  </.link>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope

    if connected?(socket) && current_scope do
      Blog.subscribe_articles(current_scope)
    end

    {:ok,
     socket
     |> assign(:current_scope, current_scope)
     |> assign(:page_title, "Listing Articles")
     |> stream(:articles, list_articles(current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    article = Blog.get_article!(socket.assigns.current_scope, id)
    {:ok, _} = Blog.delete_article(socket.assigns.current_scope, article)

    {:noreply, stream_delete(socket, :articles, article)}
  end

  @impl true
  def handle_info({type, %Alblog.Blog.Article{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :articles, list_articles(socket.assigns.current_scope), reset: true)}
  end

  defp list_articles(nil) do
    Blog.list_all_articles()
  end

  defp list_articles(current_scope) do
    Blog.list_articles(current_scope)
  end
end
