defmodule AlblogWeb.MarkdownHelper do
  @moduledoc """
  Helper functions for rendering markdown with syntax highlighting support.
  """

  @doc """
  Converts markdown to HTML with syntax highlighting support.
  Adds proper language classes to code blocks for Prism.js.
  """
  def to_html(markdown) when is_binary(markdown) do
    markdown
    |> preprocess_markdown()
    |> Earmark.as_html!(%Earmark.Options{
      code_class_prefix: "language-",
      smartypants: true,
      gfm: true
    })
    |> postprocess_links()
  end

  def to_html(nil), do: ""

  defp preprocess_markdown(markdown) do
    # Split by code blocks to avoid modifying code within them
    parts = Regex.split(~r/(`{1,3}.*?`{1,3})/s, markdown, include_captures: true)

    parts
    |> Enum.map(fn part ->
      if String.starts_with?(part, "`") do
        part
      else
        # Handle Emphasis: Replace *text* with **text**
        Regex.replace(~r/(?<!\*)\*([^\s*](?:[^*]*[^\s*])?)\*(?!\*)/, part, "**\\1**")
      end
    end)
    |> Enum.join("")
  end

  # Add target="_blank" and class="markdown-link" to all anchor tags after Earmark processing
  defp postprocess_links(html) do
    Regex.replace(
      ~r/<a href="([^"]+)">/,
      html,
      "<a href=\"\\1\" target=\"_blank\" class=\"markdown-link\">"
    )
  end
end
