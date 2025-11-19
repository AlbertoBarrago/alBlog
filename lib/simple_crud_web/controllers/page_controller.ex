defmodule SimpleCrudWeb.PageController do
  use SimpleCrudWeb, :controller

  alias SimpleCrud.Blog

  def home(conn, _params) do
    articles = Blog.list_all_articles()
    render(conn, :home, articles: articles)
  end
end
