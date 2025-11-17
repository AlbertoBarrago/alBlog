defmodule SimpleCrudWeb.ArticleLive.Index do
  use SimpleCrudWeb, :live_view

  alias SimpleCrud.Blog
  alias SimpleCrud.Accounts.Scope

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

      <.table
        id="articles"
        rows={@streams.articles}
        row_click={fn {_id, article} -> JS.navigate(~p"/articles/#{article}") end}
      >
        <:col :let={{_id, article}} label="Title">{article.title}</:col>
        <:col :let={{_id, article}} label="Slug">{article.slug}</:col>
        <:col :let={{_id, article}} label="Content">{article.content}</:col>
        <:col :let={{_id, article}} label="Published at">{article.published_at}</:col>
        <:col :let={{_id, article}} label="Category">{article.category}</:col>
        <:action :let={{_id, article}}>
          <div class="sr-only">
            <.link navigate={~p"/articles/#{article}"}>Show</.link>
          </div>
          <.link navigate={~p"/articles/#{article}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, article}}>
          <.link
            phx-click={JS.push("delete", value: %{id: article.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
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
  def handle_info({type, %SimpleCrud.Blog.Article{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :articles, list_articles(socket.assigns.current_scope), reset: true)}
  end

  defp list_articles(current_scope) do
    Blog.list_articles(current_scope)
  end
end
