defmodule PorkybankWeb.CustomPfcFormComponent do
  use PorkybankWeb, :live_component

  alias Porkybank.Repo

  @impl true
  def mount(socket) do
    changeset = Porkybank.Banking.CustomPfc.changeset(%Porkybank.Banking.CustomPfc{}, %{})
    {:ok, assign(socket, changeset: changeset)}
  end

  attr :id, :string, required: true
  attr :custom_pfc, Porkybank.Banking.CustomPfc, required: true

  def custom_pfc_form_component(assigns) do
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
        <span :if={@action == :new}>New CustomPfc</span>
        <span :if={@action == :edit}>Edit CustomPfc</span>
        <:subtitle>
          <span :if={@action == :new}>Add a custom_pfc.</span>
          <span :if={@action == :edit}>Modify this custom_pfc</span>
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
                @custom_pfc.emoji
            }
            color={
              (@changeset.changes != %{} && @changeset.changes[:color] && @changeset.changes.color) ||
                @custom_pfc.color
            }
            phx-target={@myself}
          />
        </div>
        <div class="flex justify-center items-center gap-2 relative z-10">
          <div class="flex-1">
            <.input label="Name" field={f[:name]} type="text" />
          </div>
          <%!-- Colors didn't look great --%>
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
                    style={"background-color: #{(@changeset.changes != %{} && @changeset.changes[:color] && @changeset.changes.color) || @custom_pfc.color}"}
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
        <div>
          <.input label="Description" field={f[:description]} type="text" />
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
      Porkybank.Banking.CustomPfc.changeset(assigns.custom_pfc, %{})

    {:ok,
     assign(socket,
       changeset: changeset,
       custom_pfc: assigns.custom_pfc,
       action: if(assigns.custom_pfc.id, do: :edit, else: :new)
     )}
  end

  def handle_event("validate", %{"custom_pfc" => custom_pfc}, socket) do
    changeset =
      Porkybank.Banking.CustomPfc.changeset(%Porkybank.Banking.CustomPfc{}, custom_pfc)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event(
        "save",
        %{"custom_pfc" => custom_pfc_params},
        %{:assigns => %{:action => :new}} = socket
      ) do
    changeset =
      Porkybank.Banking.CustomPfc.changeset(socket.assigns.custom_pfc, custom_pfc_params)

    case Repo.insert(changeset) do
      {:ok, _custom_pfc} ->
        {:noreply, push_navigate(socket, to: ~p"/admin/custom-pfcs")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("save", %{"custom_pfc" => custom_pfc_params}, socket) do
    changeset =
      Porkybank.Banking.CustomPfc.changeset(socket.assigns.custom_pfc, custom_pfc_params)

    case Repo.update(changeset) do
      {:ok, _custom_pfc} ->
        {:noreply, push_navigate(socket, to: ~p"/admin/custom-pfcs")}

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
      Porkybank.Banking.CustomPfc.changeset(socket.assigns.changeset, %{emoji: emoji})

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event(
        "select_color",
        %{"id" => id},
        socket
      ) do
    changeset =
      Porkybank.Banking.CustomPfc.changeset(socket.assigns.changeset, %{color: id})

    {:noreply, assign(socket, changeset: changeset)}
  end
end
