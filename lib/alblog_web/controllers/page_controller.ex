defmodule AlblogWeb.PageController do
  use AlblogWeb, :controller

  alias Alblog.Blog

  def home(conn, _params) do
    articles = Blog.list_all_articles()
    render(conn, :home, articles: articles)
  end
end
