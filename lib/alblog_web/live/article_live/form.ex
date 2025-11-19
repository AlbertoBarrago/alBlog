defmodule AlblogWeb.ArticleLive.Form do
  use AlblogWeb, :live_view

  alias Alblog.Blog
  alias Alblog.Blog.Article

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage article records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="article-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:slug]} type="text" label="Slug" disabled />

        <div class="fieldset mb-2">
          <label>
            <div class="flex items-center justify-between mb-1">
              <span class="label">Content</span>
              <button
                type="button"
                phx-click="toggle_preview"
                disabled={!@form[:content].value || @form[:content].value == ""}
                class={[
                  "text-sm font-medium transition-colors",
                  (!@form[:content].value || @form[:content].value == "") &&
                    "text-base-content/40 cursor-not-allowed",
                  @form[:content].value && @form[:content].value != "" &&
                    "text-primary hover:text-primary-focus"
                ]}
              >
                {if @preview_mode, do: "Edit", else: "Preview"}
              </button>
            </div>
            <%= if @preview_mode do %>
              <div class="prose prose-slate max-w-none p-4 border rounded-md bg-base-100 min-h-[16rem]">
                {Earmark.as_html!(@form[:content].value || "") |> Phoenix.HTML.raw()}
              </div>
              <input type="hidden" name={@form[:content].name} value={@form[:content].value} />
            <% else %>
              <textarea
                id={@form[:content].id}
                name={@form[:content].name}
                class="textarea textarea-bordered w-full h-64"
              ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:content].value) %></textarea>
            <% end %>
          </label>
          <%= for error <- @form[:content].errors do %>
            <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
              <.icon name="hero-exclamation-circle" class="size-5" />
              {translate_error(error)}
            </p>
          <% end %>
        </div>

        <.input field={@form[:published_at]} type="datetime-local" label="Published at" />

        <div class="fieldset mb-2">
          <label>
            <span class="label mb-1">Categories (Tags)</span>
            <div class="input input-bordered w-full min-h-[2.5rem] h-auto flex flex-wrap items-center gap-2 p-2 focus-within:outline-2 focus-within:outline-primary">
              <%= if @tags != [] do %>
                <%= for {tag, index} <- Enum.with_index(@tags) do %>
                  <span class={[
                    "inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-medium transition-all",
                    case rem(index, 3) do
                      0 -> "bg-primary text-primary-content"
                      1 -> "bg-info text-info-content"
                      2 -> "bg-success text-success-content"
                    end
                  ]}>
                    {tag}
                    <button
                      type="button"
                      phx-click="remove_tag"
                      phx-value-tag={tag}
                      class="inline-flex items-center justify-center hover:bg-base-content/20 rounded-full p-0.5 transition-colors focus:outline-none"
                    >
                      <span class="sr-only">Remove tag</span>
                      <svg class="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 20 20">
                        <path
                          fill-rule="evenodd"
                          d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L10 10 5.707 5.707a1 1 0 010-1.414z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </button>
                  </span>
                  <input type="hidden" name="article[category][]" value={tag} />
                <% end %>
              <% end %>
              <input type="hidden" name="article[category][]" value="" />
              <input
                type="text"
                name="tag_input"
                value={@current_tag}
                phx-keydown="handle_key"
                phx-change="update_tag_input"
                placeholder={if @tags == [], do: "Type and press Space or Tab to add tag", else: ""}
                class="flex-1 min-w-[120px] outline-none bg-transparent text-base-content border-none focus:ring-0 p-0"
              />
            </div>
          </label>
        </div>

        <footer class="mt-4 flex gap-3">
          <.button phx-disable-with="Saving..." variant="primary">Save Article</.button>
          <.button navigate={return_path(@current_scope, @return_to, @article)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:current_tag, "")
     |> assign(:preview_mode, false)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    article = Blog.get_article!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Article")
    |> assign(:article, article)
    |> assign(:tags, article.category || [])
    |> assign(:form, to_form(Blog.change_article(socket.assigns.current_scope, article)))
  end

  defp apply_action(socket, :new, _params) do
    article = %Article{
      user_id: socket.assigns.current_scope.user.id,
      published_at: DateTime.truncate(DateTime.utc_now(), :second)
    }

    socket
    |> assign(:page_title, "New Article")
    |> assign(:article, article)
    |> assign(:tags, [])
    |> assign(:form, to_form(Blog.change_article(socket.assigns.current_scope, article)))
  end

  @impl true
  def handle_event("validate", %{"article" => article_params} = params, socket) do
    # Keep the current tag input value if it exists in params
    current_tag = params["tag_input"] || socket.assigns.current_tag

    changeset =
      Blog.change_article(socket.assigns.current_scope, socket.assigns.article, article_params)

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))
     |> assign(current_tag: current_tag)}
  end

  def handle_event("update_tag_input", %{"tag_input" => value}, socket) do
    {:noreply, assign(socket, current_tag: value)}
  end

  def handle_event("handle_key", %{"key" => key, "value" => value}, socket)
      when key in [" ", "Tab", "Enter"] do
    tag = String.trim(value)

    if tag != "" and tag not in socket.assigns.tags do
      new_tags = socket.assigns.tags ++ [tag]

      # Update the changeset with new tags
      article_params =
        (socket.assigns.form.params || %{})
        |> Map.put("category", new_tags)

      changeset =
        Blog.change_article(socket.assigns.current_scope, socket.assigns.article, article_params)

      {:noreply,
       socket
       |> assign(:tags, new_tags)
       |> assign(:current_tag, "")
       |> assign(:form, to_form(changeset))}
    else
      {:noreply, assign(socket, current_tag: "")}
    end
  end

  def handle_event("handle_key", _, socket), do: {:noreply, socket}

  def handle_event("remove_tag", %{"tag" => tag_to_remove}, socket) do
    new_tags = List.delete(socket.assigns.tags, tag_to_remove)

    article_params =
      (socket.assigns.form.params || %{})
      |> Map.put("category", new_tags)

    changeset =
      Blog.change_article(socket.assigns.current_scope, socket.assigns.article, article_params)

    {:noreply,
     socket
     |> assign(:tags, new_tags)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("toggle_preview", _, socket) do
    {:noreply, assign(socket, preview_mode: not socket.assigns.preview_mode)}
  end

  def handle_event("save", %{"article" => article_params}, socket) do
    save_article(socket, socket.assigns.live_action, article_params)
  end

  defp save_article(socket, :edit, article_params) do
    case Blog.update_article(socket.assigns.current_scope, socket.assigns.article, article_params) do
      {:ok, article} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, article)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_article(socket, :new, article_params) do
    case Blog.create_article(socket.assigns.current_scope, article_params) do
      {:ok, article} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, article)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _article), do: ~p"/articles"
  defp return_path(_scope, "show", article), do: ~p"/articles/#{article}"
end
