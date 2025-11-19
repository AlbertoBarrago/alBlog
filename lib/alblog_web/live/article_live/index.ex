defmodule AlblogWeb.ArticleLive.Index do
  use AlblogWeb, :live_view

  alias Alblog.Blog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Articles
        <:actions>
          <.button variant="primary" navigate={~p"/articles/new"}>
            <.icon name="hero-plus" /> New Article
          </.button>
        </:actions>
      </.header>

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
              {article.published_at}
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
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope

    if connected?(socket) do
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

  defp list_articles(current_scope) do
    Blog.list_articles(current_scope)
  end
end
