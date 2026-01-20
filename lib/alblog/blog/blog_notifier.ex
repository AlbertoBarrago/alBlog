defmodule Alblog.Blog.BlogNotifier do
  @moduledoc """
  Handles email notifications for blog events like new comments and visit digests.
  """
  import Swoosh.Email

  alias Alblog.Mailer

  defp admin_email do
    System.get_env("ADMIN_EMAIL") || System.get_env("GMAIL_USERNAME") || "admin@example.com"
  end

  defp from_email do
    System.get_env("GMAIL_USERNAME") || "contact@example.com"
  end

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Alblog", from_email()})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Sends a notification when a new comment is posted on an article.
  """
  def deliver_new_comment_notification(article, comment, commenter) do
    deliver(admin_email(), "[Alblog] New comment on: #{article.title}", """

    ==============================

    New Comment on Your Blog!

    Article: #{article.title}

    Commenter: #{commenter.username} (#{commenter.email})

    Comment:
    #{comment.body}

    ==============================
    """)
  end

  @doc """
  Sends a daily digest of article visits.

  Expects a list of maps with :title and :visit_count keys.
  """
  def deliver_daily_visit_digest(visits_summary, date) do
    total_visits = Enum.reduce(visits_summary, 0, fn v, acc -> acc + v.visit_count end)

    article_list =
      visits_summary
      |> Enum.sort_by(& &1.visit_count, :desc)
      |> Enum.map(fn v -> "  - #{v.title}: #{v.visit_count} visits" end)
      |> Enum.join("\n")

    deliver(admin_email(), "[Alblog] Daily Visit Digest - #{date}", """

    ==============================

    Daily Visit Digest for #{date}

    Total visits: #{total_visits}

    Articles visited:
    #{article_list}

    ==============================
    """)
  end
end
