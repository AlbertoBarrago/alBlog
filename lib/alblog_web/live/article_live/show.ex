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
          <.button variant="primary" navigate={~p"/articles/#{@article}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit article
          </.button>
        </:actions>
      </.header>

      <div class="mt-6 border-t border-gray-100">
        <dl class="divide-y divide-gray-100">
          <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
            <dt class="text-sm font-medium leading-6 text-gray-900">Title</dt>
            <dd class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
              {@article.title}
            </dd>
          </div>
          <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
            <dt class="text-sm font-medium leading-6 text-gray-900">Slug</dt>
            <dd class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
              {@article.slug}
            </dd>
          </div>
          <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
            <dt class="text-sm font-medium leading-6 text-gray-900">Content</dt>
            <dd class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
              <div class="whitespace-pre-wrap border rounded-md p-4 bg-gray-50">
                {@article.content}
              </div>
            </dd>
          </div>
          <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
            <dt class="text-sm font-medium leading-6 text-gray-900">Published at</dt>
            <dd class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
              {@article.published_at}
            </dd>
          </div>
          <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
            <dt class="text-sm font-medium leading-6 text-gray-900">Category</dt>
            <dd class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
              {@article.category}
            </dd>
          </div>
        </dl>
      </div>
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
