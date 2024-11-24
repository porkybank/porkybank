defmodule PorkybankWeb.OverviewLive do
  alias Porkybank.PlaidClient
  use PorkybankWeb, :live_view
  use PorkybankWeb.Styles.CoreStyles

  @impl true
  def render(%{format: :swiftui} = assigns) do
    ~SWIFTUI"""
    <HStack class="px-12 py-12">
      <VStack alignment="leading">
        <Text class="size-18 bold color-gray pb-1">Daily Budget</Text>
        <Text class="size-24 bold color-green">
          <%= Number.Currency.number_to_currency(Decimal.div(@total_remaining, @days_remaining)) %> / day
        </Text>
      </VStack>
      <Spacer />
      <Text class="size-32">🐷</Text>
    </HStack>
    <VStack class="px-12">
      <Divider />
      <HStack><Text class="size-10 color-gray">Monthly Expenses</Text><Spacer /></HStack>
      <Grid>
        <%= for expense <- @expenses do %>
        <HStack>
          <VStack alignment="leading">
            <Text class="bold color-gray"><%= expense.description %></Text>
            <Text class="size-12 color-gray"><%= inflect(expense.date.day) %> of month</Text>
          </VStack>
          <Spacer />
          <Text class="bold color-gray"><%= Number.Currency.number_to_currency(expense.amount) %></Text>
        </HStack>
        <Divider />
        <% end %>
      </Grid>
    </VStack>
    <VStack class="px-12">
      <HStack><Text class="size-10 color-gray">Spending</Text><Spacer /></HStack>
      <Grid>
        <HStack>
          <VStack alignment="leading">
            <Text class="bold pb-6">Income</Text>
          </VStack>
          <Spacer />
          <Text class="bold pb-6"><%= Number.Currency.number_to_currency(@income) %></Text>
        </HStack>
        <Divider />
        <HStack>
          <VStack alignment="leading">
            <Text class="bold py-6">Total Spent</Text>
          </VStack>
          <Spacer />
          <Text class="bold py-6"><%= Number.Currency.number_to_currency(@total_spent) %></Text>
        </HStack>
        <Divider />
        <HStack>
          <VStack alignment="leading">
            <Text class="bold py-6">Allowance</Text>
          </VStack>
          <Spacer />
          <Text class="bold py-6">
            <%= Number.Currency.number_to_currency(Decimal.sub(@income, @monthly_expenses)) %>
          </Text>
        </HStack>
        <Divider />
        <HStack>
          <VStack alignment="leading">
            <Text class="bold py-6">Estimated Daily Limit</Text>
          </VStack>
          <Spacer />
          <Text class="bold py-6">
            <%= Number.Currency.number_to_currency(
              Decimal.div(Decimal.sub(@income, @monthly_expenses), @days_in_month)
            ) %>
          </Text>
        </HStack>
        <Divider />
      </Grid>
    </VStack>
    <VStack class="px-12">
      <HStack><Text class="size-10 color-gray">Remaining</Text><Spacer /></HStack>
      <Grid>
        <HStack>
          <VStack alignment="leading">
            <Text class="bold pb-6">Total Remaining</Text>
          </VStack>
          <Spacer />
          <Text class="bold pb-6"><%= Number.Currency.number_to_currency(@total_remaining) %></Text>
        </HStack>
        <Divider />
        <HStack>
          <VStack alignment="leading">
            <Text class="bold py-6">Days Remaining</Text>
          </VStack>
          <Spacer />
          <Text class="bold py-6"><%= @days_remaining %></Text>
        </HStack>
        <Divider />
        <HStack>
          <VStack alignment="leading">
            <Text class="bold py-6">Tomorrow's Budget</Text>
          </VStack>
          <Spacer />
          <Text class="bold py-6"><%= Number.Currency.number_to_currency(@tomorrows_budget) %> / day</Text>
        </HStack>
      </Grid>
    </VStack>
    <Spacer />
    """
  end

  def render(assigns) do
    import PorkybankWeb.ExpenseFormComponent, only: [expense_form_component: 1]
    import PorkybankWeb.CategoryFormComponent, only: [category_form_component: 1]
    import PorkybankWeb.IncomeFormComponent, only: [income_form_component: 1]

    ~H"""
    <div :if={!@transactions_loaded} class="flex justify-center">
      <.spinner />
    </div>
    <div :if={@transactions_loaded} class="flex flex-col items-center w-full">
      <div class="flex flex-col w-full">
        <div class="flex justify-between mb-6">
          <div>
            <div class="font-bold text-zinc-400">Daily Budget</div>
            <% daily_budget =
              Decimal.div(@total_remaining, @days_remaining) %>
            <div class={[
              "font-bold text-2xl",
              if(Decimal.negative?(daily_budget), do: "text-red-600", else: "text-green-600")
            ]}>
              <%= Number.Currency.number_to_currency(daily_budget,
                unit: @current_user.unit
              ) %> / day
            </div>
          </div>
        </div>
        <div class="flex flex-col">
          <.row_header>
            <div class="flex w-full justify-between items-center">
              <span>Monthly Expenses</span>
              <span>
                <%= Number.Currency.number_to_currency(@monthly_expenses,
                  unit: @current_user.unit
                ) %>
              </span>
            </div>
          </.row_header>
          <div>
            <div>
              <div class="opacity-50">
                <.rows>
                  <.row
                    :for={expense <- @expenses}
                    phx-value-id={expense.id}
                    id={expense.id}
                    on_remove={if @live_action != :example, do: "delete"}
                    phx-click={if @live_action != :example, do: "edit"}
                    class="opacity-50"
                  >
                    <:icon>
                      <.category_emoji category={expense.category} />
                    </:icon>
                    <:title>
                      <span class="cursor-pointer">
                        <%= expense.description %>
                      </span>
                    </:title>
                    <:subtitle>
                      <span class="cursor-pointer"><%= inflect(expense.date.day) %> of month</span>
                    </:subtitle>
                    <:value>
                      <%= Number.Currency.number_to_currency(expense.amount, unit: @current_user.unit) %>
                    </:value>
                  </.row>
                </.rows>
              </div>
            </div>
          </div>
          <div class="mt-3">
            <.row_header>Spending</.row_header>
            <.rows>
              <.row>
                <:title>Income</:title>
                <:value>
                  <.link
                    patch={
                      if @live_action != :example,
                        do: ~p"/overview/income?#{PorkybankWeb.Utils.get_url_params(%{date: @date})}"
                    }
                    class="underline cursor-pointer"
                  >
                    <%= Number.Currency.number_to_currency(@income, unit: @current_user.unit) %>
                    <.icon name="hero-arrow-right-solid" class="font-bold h-2 w-2" />
                  </.link>
                </:value>
              </.row>
              <.row>
                <:title>Total Spent</:title>
                <:value>
                  <.link
                    patch={
                      if @live_action == :example,
                        do: ~p"/example/transactions",
                        else: ~p"/transactions/?#{PorkybankWeb.Utils.get_url_params(%{date: @date})}"
                    }
                    class="underline cursor-pointer"
                  >
                    <%= Number.Currency.number_to_currency(@total_spent, unit: @current_user.unit) %>
                    <.icon name="hero-arrow-right-solid" class="font-bold h-2 w-2" />
                  </.link>
                </:value>
              </.row>
              <.row>
                <:title>Allowance</:title>
                <:value>
                  <%= Number.Currency.number_to_currency(Decimal.sub(@income, @monthly_expenses),
                    unit: @current_user.unit
                  ) %>
                </:value>
              </.row>
              <.row>
                <:title>Estimated Daily Limit</:title>
                <:value>
                  <%= Number.Currency.number_to_currency(
                    Decimal.div(Decimal.sub(@income, @monthly_expenses), @days_in_month),
                    unit: @current_user.unit
                  ) %>
                </:value>
              </.row>
            </.rows>
          </div>
          <div :if={@days_remaining > 1} class="mt-3">
            <.row_header>Remaining</.row_header>
            <.rows>
              <.row>
                <:title>Total Remaining</:title>
                <:value>
                  <%= Number.Currency.number_to_currency(@total_remaining, unit: @current_user.unit) %>
                </:value>
              </.row>
              <.row>
                <:title>Days Remaining</:title>
                <:value><%= @days_remaining %></:value>
              </.row>
              <% days_unspent = assigns[:days_unspent] || 1 %>
              <.form for={%{}} phx-change="change_tomorrow_budget">
                <.row>
                  <:title>
                    <div class="flex flex-col font-bold">
                      🔮 Crystal Ball
                      <div class="flex gap-1 items-center pl-2 mt-3 sm:pl-0 sm:mt-1">
                        <input
                          name="days"
                          list="values"
                          type="range"
                          min="0"
                          max={@days_remaining}
                          value={days_unspent}
                        />
                        <span class="text-2xs text-zinc-400">
                          <%= days_unspent %> <%= Inflex.inflect("days", days_unspent) %>
                        </span>

                        <datalist id="values">
                          <option :for={n <- 1..@days_remaining} value={n} />
                        </datalist>
                      </div>
                    </div>
                  </:title>
                  <:value>
                    <div class="flex flex-col justify-end items-end gap-1">
                      <div class="flex items-center gap-1 relative">
                        <span class="text-xs font-bold whitespace-nowrap absolute text-zinc-400 left-2">
                          Spend:
                        </span>
                        <.input
                          name="amount"
                          value=""
                          type="number"
                          placeholder=""
                          class="relative z-10 bg-transparent h-7 max-w-[10rem] px-2 pl-[3.25rem] !mt-0 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                        />
                      </div>
                      <span :if={Decimal.positive?(@tomorrows_budget)} class="text-sm font-bold">
                        <%= Number.Currency.number_to_currency(@tomorrows_budget,
                          unit: @current_user.unit
                        ) %> / day
                      </span>
                      <span
                        :if={Decimal.negative?(@tomorrows_budget)}
                        class="text-sm font-bold text-red-600"
                      >
                        Exceeded budget.
                      </span>
                    </div>
                  </:value>
                </.row>
                <div
                  :if={not Decimal.negative?(@tomorrows_budget)}
                  class="text-xs font-semibold text-zinc-400 mt-2"
                >
                  If you spend <%= Number.Currency.number_to_currency(@crystal_ball_amount,
                    unit: @current_user.unit
                  ) %>
                  <span :if={days_unspent <= 1}>today</span><span :if={days_unspent > 1}>over the next <%= days_unspent %> <%= Inflex.inflect("days", days_unspent) %></span>
                  <br />you'll have
                  a daily budget of <%= Number.Currency.number_to_currency(
                    @tomorrows_budget,
                    unit: @current_user.unit
                  ) %><span :if={days_unspent === 1}> tomorrow.</span><span
                    :if={days_unspent != 1}
                    phx-no-format
                  >.</span>
                </div>
              </.form>
            </.rows>
          </div>
        </div>
      </div>
      <.modal
        :if={@live_action == :expense}
        show
        size={:md}
        id="expense-form-modal"
        on_cancel={JS.patch(~p"/overview?#{PorkybankWeb.Utils.get_url_params(%{date: @date})}")}
      >
        <.expense_form_component
          id="expense-form"
          is_setup?={false}
          expense={@expense}
          current_user={@current_user}
          date={
            if @date && !@expense.id,
              do: Porkybank.Utils.get_first_day_of_month(Date.from_iso8601!(@date))
          }
          navigate={~p"/overview?#{PorkybankWeb.Utils.get_url_params(%{date: @date})}"}
        />
      </.modal>

      <.modal
        :if={@live_action == :category}
        show
        size={:md}
        id="category-form-modal"
        on_cancel={JS.patch(~p"/overview?#{PorkybankWeb.Utils.get_url_params(%{date: @date})}")}
      >
        <.category_form_component
          id="category-form"
          category={@category}
          expense={@expense}
          patch={
            ~p"/overview/expense?#{PorkybankWeb.Utils.get_url_params(%{expense_id: @expense.id, date: @date})}"
          }
          current_user={@current_user}
        />
      </.modal>

      <.modal
        :if={@live_action == :income}
        show
        size={:md}
        id="income-form-modal"
        on_cancel={JS.patch(~p"/overview?#{PorkybankWeb.Utils.get_url_params(%{date: @date})}")}
      >
        <.income_form_component id="income-form" income={@saved_income} current_user={@current_user} />
      </.modal>
    </div>
    """
  end

  def handle_params(
        _params,
        _uri,
        %{
          assigns: %{
            live_action: :example
          }
        } = socket
      ) do
    import Ecto.Query
    expense = Porkybank.Expenses.get_expense(nil)
    category = %Porkybank.Banking.Category{}

    current_user =
      Porkybank.Accounts.User
      |> where([u], u.email == "phil@test.com")
      |> Porkybank.Repo.one!()

    saved_income = Porkybank.Incomes.get_income(current_user)

    {:noreply,
     assign(socket, %{
       page: "overview",
       current_user: current_user,
       expense: expense,
       category: category,
       saved_income: saved_income,
       date: nil,
       selected_page: :overview,
       crystal_ball_amount: 0
     })
     |> put_transactions()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    expense = Porkybank.Expenses.get_expense(params["expense_id"])
    saved_income = Porkybank.Incomes.get_income(socket.assigns.current_user)
    category = %Porkybank.Banking.Category{}

    {:noreply,
     assign(socket, %{
       page: "overview",
       expense: expense,
       category: category,
       saved_income: saved_income,
       date: params["date"],
       selected_page: :overview,
       crystal_ball_amount: 0
     })
     |> put_transactions()}
  end

  @impl true
  def handle_event("change_tomorrow_budget", params, socket) do
    number =
      if params["amount"] == "" do
        0
      else
        params["amount"]
      end

    days =
      if params["days"] == "" do
        1
      else
        String.to_integer(params["days"])
      end

    days_unspent = days

    amount = Decimal.new(number)
    tomorrow_remaining = Decimal.sub(socket.assigns.total_remaining, amount)

    divisor =
      if socket.assigns.days_remaining - days_unspent == 0 do
        1
      else
        socket.assigns.days_remaining - days_unspent
      end

    tomorrows_budget =
      Decimal.div(tomorrow_remaining, divisor)

    {:noreply,
     assign(socket, %{
       crystal_ball_amount: amount,
       tomorrows_budget: tomorrows_budget,
       days_unspent: days_unspent
     })}
  end

  def handle_event("swipe_left", params, socket) do
    Porkybank.Expenses.delete_expense(params["id"], socket.assigns.current_user)

    {:noreply, put_transactions(socket)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Porkybank.Expenses.delete_expense(id, socket.assigns.current_user)

    {:noreply, put_transactions(socket)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/overview/expense?#{PorkybankWeb.Utils.get_url_params(%{expense_id: id, date: socket.assigns.date})}"
     )}
  end

  defp put_transactions(socket) do
    user = Porkybank.Repo.preload(socket.assigns.current_user, :plaid_accounts)

    date =
      if socket.assigns.date do
        Date.from_iso8601!(socket.assigns.date)
      else
        nil
      end

    {:ok,
     %{
       total_spent: total_spent,
       today: today
     }} = PlaidClient.get_transactions(user, date: date)

    income = socket.assigns.saved_income.amount || 0
    expenses = Porkybank.Expenses.list_expenses(socket.assigns.current_user, date || today)

    assign(socket, calculate_transactions(income, expenses, total_spent, today))
  end

  defp calculate_transactions(income, expenses, total_spent, today) do
    monthly_expenses =
      Enum.reduce(expenses, 0, fn expense, total ->
        Decimal.add(expense.amount, total)
      end)

    total_remaining =
      Decimal.sub(
        income,
        Decimal.add(monthly_expenses, Decimal.from_float(total_spent))
      )

    days_in_month = Date.days_in_month(today)
    days_remaining = max(1, days_in_month - today.day)

    tomorrow =
      case days_remaining - 1 do
        0 -> 1
        n -> n
      end

    tomorrows_budget = Decimal.div(total_remaining, tomorrow)

    %{
      total_spent: total_spent,
      transactions_loaded: true,
      total_remaining: total_remaining,
      monthly_expenses: monthly_expenses,
      tomorrows_budget: tomorrows_budget,
      days_remaining: days_remaining,
      days_in_month: days_in_month,
      expenses: expenses,
      income: income,
      today: today
    }
  end

  defp inflect(number) do
    case {rem(number, 10), rem(number, 100)} do
      {1, 11} ->
        Integer.to_string(number) <> "th"

      {1, _} ->
        Integer.to_string(number) <> "st"

      {2, 12} ->
        Integer.to_string(number) <> "th"

      {2, _} ->
        Integer.to_string(number) <> "nd"

      {3, 13} ->
        Integer.to_string(number) <> "th"

      {3, _} ->
        Integer.to_string(number) <> "rd"

      _ ->
        Integer.to_string(number) <> "th"
    end
  end
end
