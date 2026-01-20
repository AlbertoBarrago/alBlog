defmodule Alblog.Blog.BlogNotifierTest do
  use Alblog.DataCase

  import Swoosh.TestAssertions
  import Alblog.AccountsFixtures
  import Alblog.BlogFixtures

  alias Alblog.Blog.BlogNotifier

  describe "deliver_new_comment_notification/3" do
    setup do
      scope = user_scope_fixture()
      article = article_fixture(scope)
      comment = comment_fixture(scope, article)
      %{article: article, comment: comment, commenter: scope.user}
    end

    test "sends email with comment details", %{
      article: article,
      comment: comment,
      commenter: commenter
    } do
      {:ok, email} = BlogNotifier.deliver_new_comment_notification(article, comment, commenter)

      assert email.subject =~ "New comment on:"
      assert email.subject =~ article.title
      assert email.text_body =~ commenter.username
      assert email.text_body =~ commenter.email
      assert email.text_body =~ comment.body
    end

    test "delivers the email", %{article: article, comment: comment, commenter: commenter} do
      {:ok, email} = BlogNotifier.deliver_new_comment_notification(article, comment, commenter)

      # Verify the email was delivered via the returned email struct
      assert email.subject == "[Alblog] New comment on: #{article.title}"
      assert_email_sent(email)
    end
  end

  describe "deliver_daily_visit_digest/2" do
    test "sends email with visit statistics" do
      visits = [
        %{title: "Article One", visit_count: 10},
        %{title: "Article Two", visit_count: 5}
      ]

      {:ok, email} = BlogNotifier.deliver_daily_visit_digest(visits, "January 19, 2026")

      assert email.subject =~ "Daily Visit Digest"
      assert email.subject =~ "January 19, 2026"
      assert email.text_body =~ "Total visits: 15"
      assert email.text_body =~ "Article One: 10 visits"
      assert email.text_body =~ "Article Two: 5 visits"
    end

    test "delivers the email" do
      visits = [%{title: "Test Article", visit_count: 3}]

      {:ok, _email} = BlogNotifier.deliver_daily_visit_digest(visits, "January 19, 2026")

      assert_email_sent(subject: "[Alblog] Daily Visit Digest - January 19, 2026")
    end
  end
end
