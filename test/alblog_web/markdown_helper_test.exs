defmodule AlblogWeb.MarkdownHelperTest do
  use ExUnit.Case, async: true
  alias AlblogWeb.MarkdownHelper

  describe "to_html/1" do
    test "renders standard markdown" do
      assert MarkdownHelper.to_html("**bold**") =~ "<strong>bold</strong>"
      assert MarkdownHelper.to_html("_italic_") =~ "<em>italic</em>"
    end

    test "renders custom *bold* syntax" do
      assert MarkdownHelper.to_html("*bold*") =~ "<strong>bold</strong>"
    end

    test "renders mixed syntax" do
      html = MarkdownHelper.to_html("*bold* and _italic_")
      assert html =~ "<strong>bold</strong>"
      assert html =~ "<em>italic</em>"
    end

    test "does not affect list items" do
      html = MarkdownHelper.to_html("* list item")
      assert html =~ "<li>"
      assert html =~ "list item"
      refute html =~ "<strong>"
    end

    test "does not affect code blocks" do
      markdown = """
      ```elixir
      *not bold*
      ```
      """

      html = MarkdownHelper.to_html(markdown)
      assert html =~ "*not bold*"
      refute html =~ "<strong>not bold</strong>"
    end

    test "does not affect inline code" do
      html = MarkdownHelper.to_html("`*not bold*`")
      assert html =~ "*not bold*</code>"
      refute html =~ "<strong>not bold</strong>"
    end

    test "handles nil" do
      assert MarkdownHelper.to_html(nil) == ""
    end
  end
end
