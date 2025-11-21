defmodule AlblogWeb.TagHelper do
  def tag_color("elixir"), do: "badge-primary"
  def tag_color("javascript"), do: "badge-warning"
  def tag_color("python"), do: "badge-success"
  def tag_color("ruby"), do: "badge-error"
  def tag_color("go"), do: "badge-info"
  def tag_color("rust"), do: "badge-secondary"
  def tag_color("java"), do: "badge-accent"
  def tag_color("typescript"), do: "badge-warning"
  def tag_color("bash"), do: "badge-neutral"
  def tag_color("sql"), do: "badge-success"
  def tag_color("lua"), do: "badge-purple"
  def tag_color("neovim"), do: "badge-secondary"
  def tag_color("vim"), do: "badge-success"
  def tag_color("terminal"), do: "badge-info"

  def tag_color(_), do: "badge-ghost"
end
