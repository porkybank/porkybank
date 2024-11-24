defmodule PorkybankWeb.TransactionFormComponent do
  use PorkybankWeb, :live_component

  alias Porkybank.Repo
  alias Porkybank.Accounts.User

  attr :id, :string, required: true
  attr :current_user, User, required: true
  attr :transaction, Porkybank.Banking.PlaidTransaction, required: true
  attr :date, :string, required: true

  def transaction_form_component(assigns) do
    ~H"<.live_component {assigns} module={__MODULE__} />"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <span :if={@action == :edit}>Edit Transaction</span>
        <span :if={@action == :new}>New Transaction</span>
        <:subtitle>
          <span :if={@action == :edit}>Edit the transaction below</span>
          <span :if={@action == :new}>Add a new transaction</span>
        </:subtitle>
      </.header>
      <.simple_form
        :let={f}
        for={@changeset}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.input label="Description" placeholder="Burgers with Lola" field={f[:name]} type="text" />
        <.input label="Amount" field={f[:amount]} type="number" step=".01" placeholder="20.00" />
        <div class="flex justify-center items-center gap-2">
          <div class="flex-1">
            <.input label="Date" field={f[:date]} type="date" />
          </div>
          <div class="flex flex-col min-w-[10rem]">
            <% cat =
              assigns[:category] ||
                @categories
                |> Enum.find(fn pfc ->
                  pfc.name == @transaction.personal_finance_category["primary"]
                end) %>
            <.label>Category</.label>
            <.dropdown_menu id="category_dropdown" position={:top_right}>
              <:action :let={attrs}>
                <div
                  phx-click={attrs.toggle}
                  class="cursor-pointer font-semibold text-sm p-[4px] px-1.5 whitespace-nowrap border border-zinc-200 flex gap-2 items-center mt-2 rounded-lg"
                >
                  <.category_emoji size={:sm} category={cat} />
                  <span><%= (cat && cat.description) || (cat && cat.name) || "Pick category" %></span>
                </div>
              </:action>
              <:item :let={attrs}>
                <div class="flex flex-col max-h-64 no-scrollbar scroll-shadows overflow-scroll">
                  <div
                    :if={cat}
                    phx-value-id={cat.name}
                    phx-target={@myself}
                    phx-click={attrs.toggle |> JS.push("select_category")}
                    class={[
                      "cursor-pointer p-2 hover:bg-zinc-100 whitespace-nowrap border-b border-zinc-200 flex gap-2 items-center",
                      "bg-zinc-100"
                    ]}
                  >
                    <.category_emoji size={:sm} category={cat} />
                    <span><%= cat.description || cat.name %></span>
                  </div>
                  <div
                    :for={category <- @categories}
                    :if={
                      category.name != @transaction.personal_finance_category["primary"] &&
                        if cat, do: category.id != cat.id, else: true
                    }
                    phx-value-id={category.name}
                    phx-target={@myself}
                    phx-click={attrs.toggle |> JS.push("select_category")}
                    class="cursor-pointer p-2 hover:bg-zinc-100 whitespace-nowrap border-b border-zinc-200 flex gap-2 items-center"
                  >
                    <.category_emoji size={:sm} category={category} />
                    <span><%= category.description || category.name %></span>
                  </div>
                </div>
                <.link
                  navigate={
                    if @transaction.transaction_id,
                      do: ~p"/transactions/#{@transaction.transaction_id}/category",
                      else: ~p"/transactions/category"
                  }
                  class="cursor-pointer px-4 py-2 hover:bg-zinc-100 whitespace-nowrap flex gap-2 items-center"
                >
                  New Category <.icon name="hero-plus-circle-solid" class="text-zinc-600" />
                </.link>
              </:item>
            </.dropdown_menu>
          </div>
        </div>
        <.button phx-disable-with="Saving..." type="submit">Save</.button>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    categories = Porkybank.Categories.get_categories(assigns.current_user.id)

    changeset =
      Porkybank.Banking.PlaidTransaction.manual_changeset(assigns.transaction, %{
        date: assigns.transaction.date || Date.utc_today() |> Date.to_iso8601()
      })

    {:ok,
     assign(socket,
       changeset: changeset,
       transaction: assigns.transaction,
       current_user: assigns.current_user,
       date: assigns.date,
       categories: categories,
       action: if(assigns.transaction.id, do: :edit, else: :new)
     )}
  end

  def handle_event("select_category", %{"id" => name}, socket) do
    changeset =
      Ecto.Changeset.put_change(socket.assigns.changeset, :personal_finance_category, %{
        "primary" => name
      })

    category = socket.assigns.categories |> Enum.find(fn cat -> cat.name == name end)

    {:noreply, assign(socket, changeset: changeset, category: category)}
  end

  def handle_event("validate", %{"plaid_transaction" => transaction}, socket) do
    changeset =
      Porkybank.Banking.PlaidTransaction.manual_changeset(socket.assigns.transaction, transaction)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event(
        "save",
        %{"plaid_transaction" => transaction_params},
        %{:assigns => %{:action => :new}} = socket
      ) do
    changeset =
      Porkybank.Banking.PlaidTransaction.manual_changeset(
        socket.assigns.transaction,
        transaction_params
      )
      |> Ecto.Changeset.change(%{is_manual: true})
      |> Ecto.Changeset.change(%{transaction_id: Ecto.UUID.generate()})
      |> Ecto.Changeset.put_assoc(:user, socket.assigns.current_user)

    changeset =
      if socket.assigns[:category] do
        Ecto.Changeset.put_change(changeset, :personal_finance_category, %{
          "primary" => socket.assigns.category.name
        })
      else
        changeset
      end

    case Repo.insert(changeset) do
      {:ok, _transaction} ->
        {:noreply,
         socket
         |> push_patch(
           to:
             ~p"/transactions?#{PorkybankWeb.Utils.get_url_params(%{date: socket.assigns.date})}"
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("save", %{"plaid_transaction" => transaction_params}, socket) do
    changeset =
      Porkybank.Banking.PlaidTransaction.manual_changeset(
        socket.assigns.transaction,
        transaction_params
      )

    changeset =
      if socket.assigns[:category] do
        Ecto.Changeset.put_change(changeset, :personal_finance_category, %{
          "primary" => socket.assigns.category.name
        })
      else
        changeset
      end

    case Repo.update(changeset) do
      {:ok, _transaction} ->
        {:noreply,
         socket
         |> push_patch(
           to:
             ~p"/transactions?#{PorkybankWeb.Utils.get_url_params(%{date: socket.assigns.date})}"
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
