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
    # Split by code blocks to avoid modifying code
    # Regex matches ```...``` blocks or inline `...` code
    parts = Regex.split(~r/(`{1,3}.*?`{1,3})/s, markdown, include_captures: true)

    parts
    |> Enum.map(fn part ->
      if String.starts_with?(part, "`") do
        part
      else
        # Replace *text* with **text**, but not * at start of line (lists)
        # and not **text** (already bold)
        Regex.replace(~r/(?<!\*)\*([^\s*](?:[^*]*[^\s*])?)\*(?!\*)/, part, "**\\1**")
      end
    end)
    |> Enum.join("")
  end
end
