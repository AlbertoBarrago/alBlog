defmodule AlblogWeb.TagHelper do
  @doc """
  Returns a consistent badge color class for a given tag.
  Uses a hash of the tag name to ensure the same tag always gets the same color.
  """
  def tag_color(tag) when is_binary(tag) do
    # Use Erlang's :erlang.phash2 to get a consistent hash for the tag
    hash = :erlang.phash2(tag, 6)

    case hash do
      0 -> "badge-primary"
      1 -> "badge-secondary"
      2 -> "badge-accent"
      3 -> "badge-info"
      4 -> "badge-success"
      5 -> "badge-warning"
    end
  end

  def tag_color(_), do: "badge-ghost"
end
