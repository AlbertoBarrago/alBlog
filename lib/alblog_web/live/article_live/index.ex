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
          class="bg-white overflow-hidden shadow-lg rounded-xl flex flex-col transition duration-300 hover:shadow-2xl"
        >
          <div class="px-6 py-8 flex-grow">
            <div class="flex justify-between items-start mb-4">
              <h3 class="text-2xl font-bold text-gray-900 leading-tight">
                <.link navigate={~p"/articles/#{article}"} class="hover:text-indigo-600 transition">
                  {article.title}
                </.link>
              </h3>
              <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-indigo-50 text-indigo-700">
                {article.category}
              </span>
            </div>
            <div class="mb-4 text-sm text-gray-500 flex items-center">
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
            <div class="text-gray-600 leading-relaxed line-clamp-4">
              {article.content}
            </div>
          </div>
          <div class="bg-gray-50 px-6 py-4 flex justify-between items-center border-t border-gray-100">
            <.link
              navigate={~p"/articles/#{article}"}
              class="text-base font-semibold text-indigo-600 hover:text-indigo-500 transition flex items-center"
            >
              Read full article <span aria-hidden="true" class="ml-1">&rarr;</span>
            </.link>
            <div class="flex space-x-4">
              <.link
                navigate={~p"/articles/#{article}/edit"}
                class="text-sm font-medium text-gray-500 hover:text-gray-700 transition"
              >
                Edit
              </.link>
              <.link
                phx-click={JS.push("delete", value: %{id: article.id}) |> hide("##{id}")}
                data-confirm="Are you sure?"
                class="text-sm font-medium text-red-500 hover:text-red-700 transition"
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
