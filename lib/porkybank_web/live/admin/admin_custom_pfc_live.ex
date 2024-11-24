defmodule PorkybankWeb.Admin.AdminCustomPfcLive do
  use PorkybankWeb, :live_view_admin

  import Ecto.Query
  import PorkybankWeb.CustomPfcFormComponent, only: [custom_pfc_form_component: 1]

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between items-center">
        <div class="font-bold text-zinc-400">Categories</div>
        <div class="flex items-center">
          <.button phx-click="add">
            Add Custom Pfc
          </.button>
        </div>
      </div>
      <div class="flex flex-col gap-3 mt-4">
        <div :for={custom_pfc <- @categories}>
          <.rows>
            <.row phx-click="edit" id={custom_pfc.id} phx-value-id={custom_pfc.id} on_remove="delete">
              <:icon :if={custom_pfc}>
                <.category_emoji category={custom_pfc} />
              </:icon>
              <:title>
                <%= custom_pfc.name %>
              </:title>
              <:subtitle>
                <%= custom_pfc.description %>
              </:subtitle>
              <:value>
                <span class="text-zinc-400 whitespace-nowrap">
                  <%= Date.to_string(custom_pfc.inserted_at) %>
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
      id="custom_pfc-form-modal"
      show
      on_cancel={JS.navigate(~p"/admin/custom-pfcs")}
    >
      <.custom_pfc_form_component custom_pfc={@custom_pfc} id="custom_pfc-form" />
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, %{
       show_modal: false,
       custom_pfc: %Porkybank.Banking.CustomPfc{},
       page_selected: :custom_pfcs
     })
     |> put_categories()}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    custom_pfc = Porkybank.Repo.get(Porkybank.Banking.CustomPfc, id)

    {:noreply,
     assign(socket, %{
       custom_pfc: custom_pfc,
       show_modal: true
     })}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    custom_pfc = Porkybank.Repo.get(Porkybank.Banking.CustomPfc, id)

    socket =
      case Porkybank.Repo.delete(custom_pfc) do
        {:ok, _} ->
          put_flash(socket, :info, "CustomPfc deleted successfully.")

        {:error, _} ->
          put_flash(socket, :error, "CustomPfc could not be deleted.")
      end

    {:noreply, put_categories(socket)}
  end

  def handle_event("add", _params, socket) do
    {:noreply,
     assign(socket, %{
       custom_pfc: %Porkybank.Banking.CustomPfc{},
       show_modal: true
     })}
  end

  defp put_categories(socket) do
    query = from(c in Porkybank.Banking.CustomPfc, order_by: [desc: c.inserted_at])

    categories = Porkybank.Repo.all(query)

    assign(socket, categories: categories)
  end
end
