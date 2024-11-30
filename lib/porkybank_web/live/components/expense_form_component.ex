defmodule PorkybankWeb.ExpenseFormComponent do
  use PorkybankWeb, :live_component

  import Ecto.Query

  alias Porkybank.Repo

  def expense_form_component(assigns) do
    ~H"<.live_component {assigns} module={__MODULE__} />"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <span :if={@action == :new}>New Monthly Expense</span>
        <span :if={@action == :edit}>Edit Monthly Expense</span>
        <:subtitle>
          <span :if={@action == :new}>Add a monthly recurring expense.</span>
          <span :if={@action == :edit}>Modify this monthly recurring expense</span>
        </:subtitle>
      </.header>
      <.simple_form
        :let={f}
        for={@changeset}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.input label="Description" placeholder="Rent" field={f[:description]} type="text" />
        <.input label="Amount" field={f[:amount]} type="number" step=".01" />
        <div class="flex justify-center items-center gap-2">
          <div class="flex-1">
            <.input label="Date" field={f[:date]} type="date" />
          </div>
          <div class="flex flex-col min-w-[10rem]">
            <.label>Category</.label>
            <.dropdown_menu id="category_dropdown" position={:top_right}>
              <:action :let={attrs}>
                <div
                  phx-click={attrs.toggle}
                  class="cursor-pointer font-semibold text-sm p-[4px] px-1.5 whitespace-nowrap border border-zinc-200 flex gap-2 items-center mt-2 rounded-lg"
                >
                  <.category_emoji size={:sm} category={@expense.category} />
                  <span><%= (@expense.category && @expense.category.name) || "Pick category" %></span>
                </div>
              </:action>
              <:item :let={attrs}>
                <div class="flex flex-col max-h-64 no-scrollbar scroll-shadows overflow-scroll">
                  <div
                    :if={@expense.category}
                    phx-value-id={@expense.category.id}
                    phx-target={@myself}
                    phx-click={attrs.toggle |> JS.push("select_category")}
                    class="cursor-pointer p-2 bg-zinc-100 whitespace-nowrap border-b border-zinc-200 flex gap-2 items-center"
                  >
                    <.category_emoji size={:sm} category={@expense.category} />
                    <span><%= @expense.category.name %></span>
                  </div>
                  <div
                    :for={category <- @categories}
                    :if={category.id != @expense.category_id}
                    phx-value-id={category.id}
                    phx-target={@myself}
                    phx-click={attrs.toggle |> JS.push("select_category")}
                    class="cursor-pointer p-2 hover:bg-zinc-100 whitespace-nowrap border-b border-zinc-200 flex gap-2 items-center"
                  >
                    <.category_emoji size={:sm} category={category} />
                    <span><%= category.name %></span>
                  </div>
                </div>
                <.link
                  :if={!@is_setup?}
                  navigate={
                    ~p"/overview/category?#{if @expense.id, do: "#%{expense_id: @expense.id}", else: ""}"
                  }
                  class="cursor-pointer px-4 py-2 hover:bg-zinc-100 whitespace-nowrap flex gap-2 items-center"
                >
                  New Category <.icon name="hero-plus-circle-solid" class="text-zinc-600" />
                </.link>
              </:item>
            </.dropdown_menu>
          </div>
        </div>
        <.input
          description="Optional alias to match this expense with incoming transactions. For example, set to 'Venmo' if your rent payment appears as 'Venmo' in bank transactions."
          label="Expense Alias"
          field={f[:expense_alias]}
        />
        <.input field={f[:recurring_period]} type="hidden" />
        <.button type="submit">Save</.button>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset =
      Porkybank.Banking.Expense.changeset(assigns.expense, %{
        date:
          assigns[:date] || assigns.expense.date ||
            Date.utc_today() |> Date.beginning_of_month() |> Date.to_iso8601()
      })

    categories =
      Repo.all(
        from c in Porkybank.Banking.Category,
          where: c.user_id == ^assigns.current_user.id or is_nil(c.user_id),
          order_by: [asc: c.name]
      )

    {:ok,
     assign(socket,
       changeset: changeset,
       categories: categories,
       expense: assigns.expense,
       navigate: assigns.navigate,
       current_user: assigns.current_user,
       is_setup?: assigns.is_setup?,
       action: if(assigns.expense.id, do: :edit, else: :new)
     )}
  end

  def handle_event("validate", %{"expense" => expense}, socket) do
    changeset =
      Porkybank.Banking.Expense.changeset(socket.assigns.expense, expense)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event(
        "save",
        %{"expense" => expense_params},
        %{:assigns => %{:action => :new}} = socket
      ) do
    changeset =
      Porkybank.Banking.Expense.changeset(socket.assigns.expense, expense_params)
      |> Ecto.Changeset.put_assoc(:user, socket.assigns.current_user)

    case Repo.insert(changeset) do
      {:ok, _expense} ->
        {:noreply, push_navigate(socket, to: socket.assigns.navigate)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("save", %{"expense" => expense_params}, socket) do
    changeset = Porkybank.Banking.Expense.changeset(socket.assigns.expense, expense_params)

    case Repo.update(changeset) do
      {:ok, _expense} ->
        {:noreply, push_patch(socket, to: socket.assigns.navigate)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("select_category", %{"id" => id}, %{:assigns => %{:action => :new}} = socket) do
    category = Repo.get(Porkybank.Banking.Category, id)

    {:noreply,
     assign(socket, %{
       expense: %Porkybank.Banking.Expense{
         category: category,
         category_id: category.id
       }
     })}
  end

  def handle_event("select_category", %{"id" => id}, socket) do
    category = Repo.get(Porkybank.Banking.Category, id)

    changeset =
      Porkybank.Banking.Expense.changeset(socket.assigns.expense, %{category_id: category.id})

    {:ok, expense} = Repo.update(changeset)
    expense = Repo.preload(expense, :category)

    {:noreply,
     assign(socket, %{
       expense: expense
     })}
  end
end
