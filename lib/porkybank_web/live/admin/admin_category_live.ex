defmodule PorkybankWeb.Admin.AdminCategoryLive do
  use PorkybankWeb, :live_view_admin

  import Ecto.Query
  import PorkybankWeb.CategoryFormComponent, only: [category_form_component: 1]

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between items-center">
        <div class="font-bold text-zinc-400">Categories</div>
        <div class="flex items-center">
          <.button phx-click="add">
            Add Category
          </.button>
        </div>
      </div>
      <div class="flex flex-col gap-3 mt-4">
        <div :for={category <- @categories}>
          <.rows>
            <.row phx-click="edit" id={category.id} phx-value-id={category.id} on_remove="delete">
              <:icon :if={category}>
                <.category_emoji category={category} />
              </:icon>
              <:title>
                <%= category.name %>
              </:title>
              <:subtitle>
                <%= category.description %>
              </:subtitle>
              <:value>
                <span class="text-zinc-400 whitespace-nowrap">
                  <%= Date.to_string(category.inserted_at) %>
                </span>
              </:value>
            </.row>
          </.rows>
        </div>
      </div>
    </div>

    <.modal
      :if={@show_modal}
      size={:md}
      id="category-form-modal"
      show
      on_cancel={JS.patch(~p"/admin/categories")}
    >
      <.category_form_component
        patch={~p"/admin/categories"}
        id="category-form"
        category={@category}
        current_user={nil}
      />
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, %{
       show_modal: false,
       category: %Porkybank.Banking.Category{},
       page_selected: :categories
     })
     |> put_categories()}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    category = Porkybank.Repo.get(Porkybank.Banking.Category, id)

    {:noreply,
     assign(socket, %{
       category: category,
       show_modal: true
     })}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    category = Porkybank.Repo.get(Porkybank.Banking.Category, id)

    socket =
      case Porkybank.Repo.delete(category) do
        {:ok, _} ->
          put_flash(socket, :info, "Category deleted successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Category could not be deleted.")
      end

    {:noreply, put_categories(socket)}
  end

  def handle_event("add", _params, socket) do
    {:noreply,
     assign(socket, %{
       category: %Porkybank.Banking.Category{},
       show_modal: true
     })}
  end

  defp put_categories(socket) do
    query = from(c in Porkybank.Banking.Category, order_by: [desc: c.inserted_at])

    categories = Porkybank.Repo.all(query)

    assign(socket, categories: categories)
  end
end
