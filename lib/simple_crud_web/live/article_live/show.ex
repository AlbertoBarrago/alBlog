defmodule SimpleCrudWeb.ArticleLive.Show do
  use SimpleCrudWeb, :live_view

  alias SimpleCrud.Blog

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

      <.list>
        <:item title="Title">{@article.title}</:item>
        <:item title="Slug">{@article.slug}</:item>
        <:item title="Content">{@article.content}</:item>
        <:item title="Published at">{@article.published_at}</:item>
        <:item title="Category">{@article.category}</:item>
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
  def handle_info(
        {:updated, %SimpleCrud.Blog.Article{id: id} = article},
        %{assigns: %{article: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :article, article)}
  end

  def handle_info(
        {:deleted, %SimpleCrud.Blog.Article{id: id}},
        %{assigns: %{article: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current article was deleted.")
     |> push_navigate(to: ~p"/articles")}
  end

  def handle_info({type, %SimpleCrud.Blog.Article{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
