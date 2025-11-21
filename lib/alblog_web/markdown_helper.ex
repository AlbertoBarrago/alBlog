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
    |> Earmark.as_html!(%Earmark.Options{
      code_class_prefix: "language-",
      smartypants: true,
      gfm: true
    })
  end

  def to_html(nil), do: ""
end
