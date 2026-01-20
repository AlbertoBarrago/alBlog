defmodule Alblog.Blog.ArticleVisitTest do
  use Alblog.DataCase

  import Alblog.AccountsFixtures
  import Alblog.BlogFixtures

  alias Alblog.Blog

  describe "record_article_visit/1" do
    setup do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      %{article: article}
    end

    test "creates a new visit record for today", %{article: article} do
      assert {:ok, visit} = Blog.record_article_visit(article.id)

      assert visit.article_id == article.id
      assert visit.date == Date.utc_today()
      assert visit.visit_count == 1
    end

    test "increments visit count on subsequent visits", %{article: article} do
      {:ok, _} = Blog.record_article_visit(article.id)
      {:ok, _} = Blog.record_article_visit(article.id)
      {:ok, _} = Blog.record_article_visit(article.id)

      # Check the visit count in the database
      visits = Blog.get_visits_for_date(Date.utc_today())
      article_visit = Enum.find(visits, &(&1.article_id == article.id))

      assert article_visit.visit_count == 3
    end

    test "tracks visits separately per article", %{article: article} do
      scope = user_scope_fixture()
      other_article = article_fixture(scope, %{title: "Other article"})

      {:ok, _} = Blog.record_article_visit(article.id)
      {:ok, _} = Blog.record_article_visit(article.id)
      {:ok, _} = Blog.record_article_visit(other_article.id)

      visits = Blog.get_visits_for_date(Date.utc_today())

      article1_visit = Enum.find(visits, &(&1.article_id == article.id))
      article2_visit = Enum.find(visits, &(&1.article_id == other_article.id))

      assert article1_visit.visit_count == 2
      assert article2_visit.visit_count == 1
    end
  end

  describe "get_visits_for_date/1" do
    setup do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      %{article: article, scope: scope}
    end

    test "returns visits for a specific date", %{article: article} do
      today = Date.utc_today()
      {:ok, _} = Blog.record_article_visit(article.id)

      visits = Blog.get_visits_for_date(today)

      assert length(visits) == 1
      assert hd(visits).title == article.title
      assert hd(visits).visit_count == 1
    end

    test "returns empty list for dates with no visits", %{article: _article} do
      yesterday = Date.add(Date.utc_today(), -1)

      visits = Blog.get_visits_for_date(yesterday)

      assert visits == []
    end

    test "includes article title in results", %{article: article} do
      {:ok, _} = Blog.record_article_visit(article.id)

      [visit] = Blog.get_visits_for_date(Date.utc_today())

      assert visit.title == article.title
      assert visit.article_id == article.id
    end
  end

  describe "send_daily_visit_digest/0" do
    setup do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      %{article: article}
    end

    test "returns :no_visits when no visits yesterday" do
      assert {:ok, :no_visits} = Blog.send_daily_visit_digest()
    end

    test "sends digest when there are visits yesterday", %{article: article} do
      yesterday = Date.add(Date.utc_today(), -1)

      # Insert a visit for yesterday
      Alblog.Repo.insert!(%Alblog.Blog.ArticleVisit{
        article_id: article.id,
        date: yesterday,
        visit_count: 5
      })

      assert {:ok, _email} = Blog.send_daily_visit_digest()
    end
  end
end
