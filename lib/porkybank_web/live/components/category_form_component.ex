defmodule PorkybankWeb.CategoryFormComponent do
  use PorkybankWeb, :live_component

  alias Porkybank.Repo

  @impl true
  def mount(socket, assigns) do
    changeset =
      Porkybank.Banking.Category.changeset(
        %Porkybank.Banking.Category{},
        %{},
        assigns.current_user.id
      )

    {:ok, assign(socket, changeset: changeset)}
  end

  attr :expense, Porkybank.Banking.Expense, default: nil
  attr :id, :string, required: true
  attr :current_user, :any, required: true
  attr :category, Porkybank.Banking.Category, default: nil
  attr :transaction, Porkybank.Banking.PlaidTransaction, default: nil
  attr :patch, :string, default: nil

  def category_form_component(assigns) do
    ~H"<.live_component {assigns} module={__MODULE__} />"
  end

  def colors() do
    [
      "#2A363B",
      "#355C7D",
      "#6C5B7B",
      "#878fc6",
      "#99B898",
      "#C06C84",
      "#C27BA0",
      "#E69853",
      "#E84A5F",
      "#F08A5D",
      "#F67280",
      "#F9D56E",
      "#FECEAB",
      "#FF847C",
      "#FFC857"
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <span :if={@action == :new}>New Category</span>
        <span :if={@action == :edit}>Edit Category</span>
        <:subtitle>
          <span :if={@action == :new}>Add a category.</span>
          <span :if={@action == :edit}>Modify this category</span>
        </:subtitle>
      </.header>
      <.simple_form
        :let={f}
        for={@changeset}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <div class="flex justify-center relative z-20">
          <.emoji_picker
            emoji={
              (@changeset.changes != %{} && @changeset.changes[:emoji] && @changeset.changes.emoji) ||
                @category.emoji
            }
            color={
              (@changeset.changes != %{} && @changeset.changes[:color] && @changeset.changes.color) ||
                @category.color
            }
            phx-target={@myself}
          />
        </div>
        <div class="flex justify-center items-center gap-2 relative z-10">
          <div class="flex-1">
            <.input label="Name" field={f[:name]} type="text" />
          </div>
          <div class="flex flex-col">
            <.label>Color</.label>
            <.dropdown_menu id="color_dropdown" position={:bottom_right}>
              <:action :let={attrs}>
                <.button
                  type="button"
                  variant={:shadow}
                  phx-click={attrs.toggle}
                  class="mt-2 h-[42px] flex justify-center items-center gap-2"
                >
                  <span
                    class="h-6 w-6 rounded-full"
                    style={"background-color: #{(@changeset.changes != %{} && @changeset.changes[:color] && @changeset.changes.color) || @category.color}"}
                  >
                  </span>
                </.button>
              </:action>
              <:item :let={attrs}>
                <div class="grid grid-cols-5 w-72 p-4">
                  <div
                    :for={color <- colors()}
                    phx-value-id={color}
                    phx-target={@myself}
                    phx-click={attrs.toggle |> JS.push("select_color")}
                    class="cursor-pointer rounded-xl p-3 flex justify-center items-center hover:bg-zinc-100"
                  >
                    <span class="h-6 w-6 rounded-full" style={"background-color: #{color}"}></span>
                  </div>
                </div>
              </:item>
            </.dropdown_menu>
          </div>
        </div>
        <div class="hidden">
          <.input field={f[:color]} type="hidden" class="hidden" />
          <.input id="emoji" field={f[:emoji]} type="hidden" class="hidden" />
        </div>
        <.button type="submit">Save</.button>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset =
      Porkybank.Banking.Category.changeset(assigns.category, %{}, assigns.current_user.id)

    {:ok,
     assign(socket,
       changeset: changeset,
       category: assigns.category,
       expense: assigns.expense,
       transaction: assigns.transaction,
       patch: assigns.patch,
       current_user: assigns.current_user,
       action: if(assigns.category.id, do: :edit, else: :new)
     )}
  end

  def handle_event("validate", %{"category" => category}, socket) do
    changeset =
      Porkybank.Banking.Category.changeset(
        %Porkybank.Banking.Category{},
        category,
        socket.assigns.current_user.id
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event(
        "save",
        %{"category" => category_params},
        %{:assigns => %{:action => :new}} = socket
      ) do
    changeset =
      Porkybank.Banking.Category.changeset(
        socket.assigns.category,
        category_params,
        socket.assigns.current_user.id
      )
      |> Ecto.Changeset.put_assoc(:user, socket.assigns.current_user)

    case Repo.insert(changeset) do
      {:ok, category} ->
        if socket.assigns[:expense] do
          Porkybank.Repo.update(
            Porkybank.Banking.Expense.changeset(socket.assigns.expense, %{
              category_id: category.id
            })
          )
        end

        if socket.assigns[:transaction] do
          Porkybank.Repo.update(
            Porkybank.Banking.PlaidTransaction.manual_changeset(socket.assigns.transaction, %{
              personal_finance_category: %{
                "primary" => category.name
              }
            })
          )
        end

        {:noreply,
         push_patch(socket, to: socket.assigns[:patch] <> "?category_id=#{category.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("save", %{"category" => category_params}, socket) do
    changeset =
      Porkybank.Banking.Category.changeset(
        socket.assigns.category,
        category_params,
        socket.assigns.current_user.id
      )

    case Repo.update(changeset) do
      {:ok, _category} ->
        {:noreply, push_patch(socket, to: socket.assigns[:patch])}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event(
        "emoji_selected",
        %{"emoji" => emoji},
        socket
      ) do
    changeset =
      Porkybank.Banking.Category.changeset(
        socket.assigns.changeset,
        %{emoji: emoji},
        socket.assigns.current_user.id
      )

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event(
        "select_color",
        %{"id" => id},
        socket
      ) do
    changeset =
      Porkybank.Banking.Category.changeset(
        socket.assigns.changeset,
        %{color: id},
        socket.assigns.current_user.id
      )

    {:noreply, assign(socket, changeset: changeset)}
  end
end
