defmodule PorkybankWeb.IncomeFormComponent do
  use PorkybankWeb, :live_component

  alias Porkybank.Repo

  attr :current_user, Porkybank.Accounts.User, required: true
  attr :income, Porkybank.Banking.Income, required: true
  attr :id, :string, required: true

  def income_form_component(assigns) do
    ~H"<.live_component {assigns} module={__MODULE__} />"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Income Info
        <:subtitle>
          Tell us about your monthly income.
        </:subtitle>
      </.header>
      <.simple_form
        :let={f}
        for={@changeset}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.input label="Amount" field={f[:amount]} type="number" step=".01" />
        <.button phx-disable-with="Saving..." type="submit">Save</.button>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset = Porkybank.Banking.Income.changeset(assigns.income, %{})

    {:ok,
     assign(socket,
       changeset: changeset,
       income: assigns.income,
       current_user: assigns.current_user,
       action: if(assigns.income.id, do: :edit, else: :new)
     )}
  end

  def handle_event("validate", %{"income" => income}, socket) do
    changeset =
      Porkybank.Banking.Income.changeset(socket.assigns.income, income)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event(
        "save",
        %{"income" => income_params},
        %{:assigns => %{:action => :new}} = socket
      ) do
    changeset =
      Porkybank.Banking.Income.changeset(socket.assigns.income, income_params)
      |> Ecto.Changeset.put_assoc(:user, socket.assigns.current_user)

    case Repo.insert(changeset) do
      {:ok, _income} ->
        {:noreply, redirect(socket, to: "/overview")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("save", %{"income" => income_params}, socket) do
    changeset = Porkybank.Banking.Income.changeset(socket.assigns.income, income_params)

    case Repo.update(changeset) do
      {:ok, _income} ->
        {:noreply, redirect(socket, to: "/overview")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
