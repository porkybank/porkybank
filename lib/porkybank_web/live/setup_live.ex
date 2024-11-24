defmodule PorkybankWeb.SetupLive do
  use PorkybankWeb, :live_view

  import PorkybankWeb.IncomeFormComponent, only: [income_form_component: 1]

  import PorkybankWeb.ExpenseFormComponent, only: [expense_form_component: 1]

  alias Phoenix.PubSub
  alias Porkybank.Banking.PlaidAccount
  alias Porkybank.Repo
  alias Porkybank.PlaidClient
  alias Porkybank.Users

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <div class="flex justify-between mb-6">
        <div>
          <div class="font-bold text-zinc-400">Daily Budget</div>
          <div class={[
            "font-bold text-2xl",
            if(@daily_budget != nil, do: "text-green-600", else: "text-zinc-700")
          ]}>
            <span :if={@daily_budget != nil}>
              <%= Number.Currency.number_to_currency(@daily_budget,
                unit: @current_user.unit
              ) %>
            </span>
            <span :if={@daily_budget == nil}>
              ?
            </span>
            / day
            <span
              :if={@daily_budget == nil}
              aria-label="Fill in your information below to see your daily budget"
              class="hint--right hint--rounded"
            >
              <.icon name="hero-information-circle-solid" class="text-zinc-400" />
            </span>
          </div>
        </div>
      </div>

      <div class="text-sm text-zinc-400 font-bold">
        Step <%= step_index(@step) %> of 4
      </div>
      <div class="flex gap-1 mt-2">
        <%= Enum.map(1..4, fn i -> %>
          <div class={
              "flex-1 h-1 rounded-full " <>
                if i <= step_index(@step) do
                  "bg-zinc-500"
                else
                  "bg-zinc-300"
                end
            }>
          </div>
        <% end) %>
      </div>

      <.billing_step :if={@step == :billing} {assigns} />
      <.plaid_step :if={@step == :plaid} {assigns} />
      <.income_step :if={@step == :income} {assigns} />
      <.expense_step :if={@step == :expense} {assigns} />
      <.complete_step :if={@step == :complete} {assigns} />
    </div>
    """
  end

  def billing_step(assigns) do
    ~H"""
    <div>
      Billing
    </div>
    """
  end

  def plaid_step(assigns) do
    ~H"""
    <div class="flex flex-1 flex-col gap-3 justify-between mt-4">
      <div class="text-zinc-700 font-bold">
        <.icon name="hero-plus-circle" /> Connect a bank account
        <div class="text-xs text-zinc-500 font-normal mt-1">
          Click the button below to connect a bank account. You will be
          able to connect multiple accounts later.
        </div>
      </div>
      <div class="flex flex-col gap-4">
        <div phx-hook="token" id="token" class="flex justify-center">
          <.button
            :if={@link_token}
            icon_name="hero-building-library"
            id="link-button"
            variant={:shadow}
            data-link-token={@link_token}
            data-env={Application.get_env(:porkybank, Porkybank.PlaidClient)[:env]}
          >
            Connect an account
          </.button>
          <.button :if={!@link_token}>
            Loading...
          </.button>
          <p :if={assigns["link_error"]}>Error: <%= assigns["link_error"] %></p>
        </div>
      </div>
      <div>
        <div class="flex justify-center mb-2">
          <.link phx-click="skip_plaid" class="text-sm underline text-blue-600">
            Skip this step
          </.link>
        </div>
        <div class="text-xs text-zinc-500 border-t border-zinc-200 py-2">
          Plaid is a secure service that allows us to view your transactions and balances.
          We do not have access to your bank account login information, nor can we make any
          transactions on your behalf.
        </div>
      </div>
    </div>
    """
  end

  def income_step(assigns) do
    ~H"""
    <div class="flex flex-1 flex-col gap-3 justify-between mt-4">
      <.income_form_component id="income-form" income={@income} current_user={@current_user} />
      <div class="text-xs text-zinc-500 border-t border-zinc-200 py-2">
        You can change your income later from your dashboard.
      </div>
    </div>
    """
  end

  def expense_step(assigns) do
    ~H"""
    <div class="flex flex-1 flex-col gap-3 justify-between mt-4">
      <.expense_form_component
        id="expense-form"
        is_setup?={true}
        expense={@expense}
        current_user={@current_user}
        navigate={~p"/setup/complete"}
        default_category_id={Application.get_env(:porkybank, :default_category_id)}
      />
      <div class="text-xs text-zinc-500 border-t border-zinc-200 py-2">
        You can add more expenses later from your dashboard.
      </div>
    </div>
    """
  end

  def complete_step(assigns) do
    ~H"""
    <div class="flex flex-1 flex-col gap-3 justify-between mt-4">
      <div class="text-zinc-700 font-bold">
        <.icon name="hero-check-circle-solid" class="text-green-600" /> Setup complete
        <div class="text-xs text-zinc-500 font-normal mt-1">
          You're all set! You'll be redirected to your dashboard in a few seconds, we're just
          finishing up a few things.
        </div>
      </div>
      <div class="flex flex-col items-center justify-center mt-6">
        <.spinner />
        <div class="text-xs text-zinc-500 font-normal mt-2">
          Redirecting...
        </div>
        <.link navigate="/overview" class="text-xs text-blue-600">
          Click here if you're not redirected in 5 seconds.
        </.link>
      </div>
      <div class="text-xs text-zinc-500 border-t border-zinc-200 py-2">
        You can change your income and expenses at any time from your dashboard.
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    PubSub.subscribe(Porkybank.PubSub, "transactions_updated_#{socket.assigns.current_user.id}")

    socket =
      socket
      |> put_step(params["step"], params)
      |> put_income()
      |> put_expense()
      |> put_link_token()
      |> put_preliminary_data()

    {:ok, socket, layout: {PorkybankWeb.Layouts, :setup}}
  end

  def handle_event(
        "plaid_success",
        %{
          "public_token" => public_token,
          "institution_name" => institution_name,
          "account_id" => account_id
        },
        socket
      ) do
    access_token = PlaidClient.get_access_token(public_token)

    PlaidAccount.changeset(%PlaidAccount{}, %{
      account_id: account_id,
      access_token: access_token,
      institution_name: institution_name
    })
    |> Ecto.Changeset.put_assoc(:user, socket.assigns.current_user)
    |> Repo.insert()

    Oban.insert(
      Porkybank.Workers.TransactionFetcher.new(%{user_id: socket.assigns.current_user.id})
    )

    {:noreply, put_step(socket, :incomes, %{})}
  end

  def handle_event("skip_plaid", _, socket) do
    id = socket.assigns.current_user.id
    Porkybank.Repo.get!(Porkybank.Accounts.User, id) |> Users.skip_plaid()

    {:noreply, push_navigate(socket, to: "/setup/income")}
  end

  def handle_info(
        {:updated_transactions},
        socket
      ) do
    if socket.assigns.step == :complete do
      {:noreply, push_navigate(socket, to: "/overview")}
    else
      {:noreply, socket}
    end
  end

  def put_step(socket, step, params) do
    user = Repo.preload(socket.assigns.current_user, :plaid_transactions)
    derived_step = derive_setup_step(user, step)

    params =
      if plan = params["plan"] do
        %{plan: plan}
      else
        %{}
      end

    if derived_step == :complete do
      if user.opted_out_of_plaid_at != nil || user.plaid_transactions != [] do
        push_navigate(socket, to: ~p"/overview")
      end
    else
      if step != to_string(derived_step) do
        case step do
          "transaction" ->
            assign(socket, :step, :transaction)

          _ ->
            push_navigate(socket, to: ~p"/setup/#{derived_step}?#{params}")
        end
      else
        assign(socket, :step, derived_step)
      end
    end
  end

  def derive_setup_step(user, _step_param) do
    # if user.completed_setup_at != nil do

    case Repo.preload(user, [:expenses, :incomes, :plaid_accounts]) do
      %{plaid_accounts: []} ->
        if user.opted_out_of_plaid_at != nil do
          case Repo.preload(user, [:incomes, :expenses]) do
            %{incomes: []} ->
              :income

            %{expenses: []} ->
              :expense

            _otherwise ->
              :complete
          end
        else
          :plaid
        end

      %{incomes: []} ->
        :income

      %{expenses: []} ->
        :expense

      _otherwise ->
        :complete
    end

    # else
    #   :billing
    # end
  end

  def step_index(:billing), do: 1
  def step_index(:plaid), do: 2
  def step_index(:transaction), do: 2
  def step_index(:income), do: 3
  def step_index(:expense), do: 4
  def step_index(_otherwise), do: 4

  defp put_link_token(socket) do
    case socket do
      %{assigns: %{step: :plaid}} ->
        case PlaidClient.get_link_token(socket.assigns.current_user) do
          {:ok, %{body: %{"link_token" => link_token}}} ->
            assign(socket, :link_token, link_token)

          {:error, %{"error_message" => error_message}} ->
            assign(socket, :link_error, error_message) |> assign(:link_token, nil)
        end

      _otherwise ->
        socket
    end
  end

  defp put_income(socket) do
    assign(socket, :income, %Porkybank.Banking.Income{})
  end

  defp put_expense(socket) do
    default_category_id = Application.get_env(:porkybank, :default_category_id)
    category = Repo.get(Porkybank.Banking.Category, default_category_id)

    assign(socket, :expense, %Porkybank.Banking.Expense{
      category: category
    })
  end

  defp put_preliminary_data(socket) do
    today = Date.utc_today()
    days_in_month = Date.days_in_month(today)
    days_remaining = max(1, days_in_month - today.day)

    user = Repo.preload(socket.assigns.current_user, :incomes)

    daily_budget =
      if user.incomes != [] do
        total_remaining = List.first(user.incomes).amount
        Decimal.div(total_remaining, days_remaining)
      else
        nil
      end

    assign(socket, %{
      daily_budget: daily_budget
    })
  end
end
