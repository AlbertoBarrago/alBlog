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
  end

  def to_html(nil), do: ""

  defp preprocess_markdown(markdown) do
    # 1. Split by code blocks to avoid modifying code within them
    parts = Regex.split(~r/(`{1,3}.*?`{1,3})/s, markdown, include_captures: true)

    parts
    |> Enum.map(fn part ->
      if String.starts_with?(part, "`") do
        part
      else
        # --- 1. Handle Markdown Links: Convert [Text](URL) to <a href="URL" class="markdown-link">Text</a> ---
        modified_part =
          Regex.replace(
            ~r/\[(.*?)\]\((.*?)\)/,
            part,
            fn _match, link_text, url ->
              cleaned_url =
                url
                |> String.replace(~r/["“”]/, "")
                |> String.trim()

              "<a href=\"#{cleaned_url}\" target=\"_blank\" class=\"markdown-link\">#{link_text}</a>"
            end
          )

        # --- 2. Handle Emphasis (if still needed) ---
        # Replace *text* with **text**
        Regex.replace(~r/(?<!\*)\*([^\s*](?:[^*]*[^\s*])?)\*(?!\*)/, modified_part, "**\\1**")
      end
    end)
    |> Enum.join("")
  end
end
