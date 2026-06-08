defmodule PorkybankWeb.OverviewLive do
  alias Porkybank.PlaidClient
  use PorkybankWeb, :live_view
  use PorkybankWeb.Styles.CoreStyles

  import Ecto.Query
  alias Oban

  @impl true
  def render(%{format: :swiftui} = assigns) do
    ~SWIFTUI"""
    <% exceeded? = Decimal.negative?(@total_remaining)

    {budget_label, budget_value} =
      if exceeded?,
        do: {"Exceeded by", Decimal.abs(@total_remaining)},
        else: {"Today's Budget", @todays_budget} %>
    <HStack class="px-12 py-12">
      <VStack alignment="leading">
        <Text class={[
          "size-18 bold pb-1",
          if(exceeded?, do: "color-red", else: budget_header_color(@todays_budget, @estimated_daily_limit, :swiftui))
        ]}><%= budget_label %></Text>
        <Text class={[
          "size-24 bold",
          if(exceeded?, do: "color-red", else: budget_value_color(@todays_budget, @estimated_daily_limit, :swiftui))
        ]}>
          <%= Number.Currency.number_to_currency(budget_value) %>
        </Text>
      </VStack>
      <Spacer />
      <Text class="size-32"><img class="w-4 mr-1" src={~p"/images/porkybank.png"} /></Text>
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
            <%= Number.Currency.number_to_currency(@estimated_daily_limit) %>
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
          <Text :if={exceeded?} class="bold py-6 color-red">Exceeded by <%= Number.Currency.number_to_currency(Decimal.abs(@total_remaining)) %></Text>
          <Text :if={not exceeded?} class="bold py-6"><%= Number.Currency.number_to_currency(@tomorrows_budget) %> / day</Text>
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
          <% exceeded? = Decimal.negative?(@total_remaining)

          {budget_label, budget_value} =
            cond do
              exceeded? -> {"Exceeded by", Decimal.abs(@total_remaining)}
              @budget_view == :tomorrow -> {"Tomorrow's Budget", @tomorrows_budget}
              true -> {"Today's Budget", @todays_budget}
            end %>
          <div phx-click="toggle_budget_view" class="cursor-pointer select-none">
            <div class="flex items-center gap-1">
              <div class={[
                "font-bold",
                if(exceeded?, do: "text-red-600", else: budget_header_color(budget_value, @estimated_daily_limit, :web))
              ]}>
                <%= budget_label %>
              </div>
              <div :if={@pay_cycle} class="relative group" onclick="event.stopPropagation()">
                <.icon name="hero-information-circle" class="h-4 w-4 text-zinc-400 cursor-pointer" />
                <div class="absolute left-0 top-6 z-10 hidden group-hover:flex flex-col gap-1 bg-zinc-800 text-white text-xs rounded-lg px-3 py-2 w-56 shadow-lg">
                  <span>Resets in <%= @days_until_reset %> <%= Inflex.inflect("day", @days_until_reset) %></span>
                  <span><%= Calendar.strftime(@period_start, "%b %-d") %> – <%= Calendar.strftime(@period_end, "%b %-d") %></span>
                  <span class="text-zinc-400 capitalize"><%= String.replace(@pay_cycle, "_", "-") %> pay cycle</span>
                </div>
              </div>
            </div>
            <div class={[
              "font-bold text-2xl",
              if(exceeded?, do: "text-red-600", else: budget_value_color(budget_value, @estimated_daily_limit, :web))
            ]}>
              <%= Number.Currency.number_to_currency(budget_value,
                unit: @current_user.unit
              ) %>
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
            <.row_header>Forecast</.row_header>
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
                  <%= Number.Currency.number_to_currency(@estimated_daily_limit,
                    unit: @current_user.unit
                  ) %>
                </:value>
              </.row>
            </.rows>
          </div>
          <div class="mt-3">
            <.row_header>Spending</.row_header>
            <.rows>
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
                <:title>Avg per day</:title>
                <:value>
                  <%= Number.Currency.number_to_currency(
                    Decimal.div(Decimal.from_float(@total_spent), @days_elapsed),
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
       crystal_ball_amount: 0,
       budget_view: socket.assigns[:budget_view] || :today
     })
     |> put_transactions()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    expense = Porkybank.Expenses.get_expense(params["expense_id"])
    saved_income = Porkybank.Incomes.get_income(socket.assigns.current_user)
    category = %Porkybank.Banking.Category{}

    # Check if we need to trigger monthly transactions for the requested month
    maybe_trigger_monthly_transactions(socket.assigns.current_user, params["date"])

    {:noreply,
     assign(socket, %{
       page: "overview",
       expense: expense,
       category: category,
       saved_income: saved_income,
       date: params["date"],
       selected_page: :overview,
       crystal_ball_amount: 0,
       budget_view: socket.assigns[:budget_view] || :today
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

  def handle_event("toggle_budget_view", _params, socket) do
    next =
      case socket.assigns[:budget_view] do
        :tomorrow -> :today
        _ -> :tomorrow
      end

    {:noreply, assign(socket, budget_view: next)}
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
    pay_cycle = socket.assigns.current_user.pay_cycle

    date =
      if socket.assigns.date do
        Date.from_iso8601!(socket.assigns.date)
      else
        nil
      end

    reference_date = date || Date.utc_today()
    {period_start, _} = Porkybank.PayCycle.period_for(pay_cycle, reference_date)

    {:ok,
     %{
       total_spent: total_spent,
       today_spent: today_spent,
       today: today
     }} = PlaidClient.get_transactions(user, date: date, period_start: period_start)

    income = socket.assigns.saved_income.amount || 0
    expenses = Porkybank.Expenses.list_expenses(socket.assigns.current_user, date || today)

    assign(socket, calculate_transactions(income, expenses, total_spent, today_spent, today, pay_cycle))
  end

  defp calculate_transactions(income, expenses, total_spent, today_spent, today, pay_cycle \\ nil) do
    monthly_expenses =
      Enum.reduce(expenses, 0, fn expense, total ->
        Decimal.add(expense.amount, total)
      end)

    {period_start, period_end} = Porkybank.PayCycle.period_for(pay_cycle, today)
    periods = Porkybank.PayCycle.periods_per_month(pay_cycle)
    days_until_reset = max(0, Date.diff(period_end, today))
    days_elapsed = max(1, Date.diff(today, period_start) + 1)

    days_in_month = Date.days_in_month(today)
    days_remaining = max(1, Date.diff(period_end, today))

    # Period-scaled income/expenses for Today's Budget and Total Remaining
    period_income = Decimal.div(income, periods)
    period_expenses = Decimal.div(monthly_expenses, periods)

    total_remaining =
      Decimal.sub(period_income, Decimal.add(period_expenses, Decimal.from_float(total_spent)))

    tomorrow =
      case days_remaining - 1 do
        0 -> 1
        n -> n
      end

    tomorrows_budget = Decimal.div(total_remaining, tomorrow)

    # Spending from the period up to (but not including) today is amortized
    # across the remaining days as a daily allowance. Today's spending is then
    # subtracted dollar-for-dollar so Today's Budget drops as you spend today.
    spent_before_today =
      Decimal.sub(Decimal.from_float(total_spent), Decimal.from_float(today_spent))

    remaining_before_today =
      Decimal.sub(period_income, Decimal.add(period_expenses, spent_before_today))

    todays_budget =
      Decimal.sub(
        Decimal.div(remaining_before_today, days_remaining),
        Decimal.from_float(today_spent)
      )

    # Forecast uses full monthly figures for context
    estimated_daily_limit =
      Decimal.div(Decimal.sub(income, monthly_expenses), days_in_month)

    %{
      total_spent: total_spent,
      today_spent: today_spent,
      transactions_loaded: true,
      total_remaining: total_remaining,
      monthly_expenses: monthly_expenses,
      tomorrows_budget: tomorrows_budget,
      todays_budget: todays_budget,
      estimated_daily_limit: estimated_daily_limit,
      days_remaining: days_remaining,
      days_in_month: days_in_month,
      expenses: expenses,
      income: income,
      today: today,
      pay_cycle: pay_cycle,
      period_start: period_start,
      period_end: period_end,
      days_until_reset: days_until_reset,
      days_elapsed: days_elapsed
    }
  end

  defp budget_threshold(todays_budget, estimated_daily_limit) do
    cond do
      Decimal.compare(estimated_daily_limit, Decimal.new(0)) != :gt -> :ok
      Decimal.compare(todays_budget, Decimal.div(estimated_daily_limit, 4)) == :lt -> :red
      Decimal.compare(todays_budget, Decimal.div(estimated_daily_limit, 2)) == :lt -> :yellow
      true -> :ok
    end
  end

  defp budget_header_color(todays_budget, estimated_daily_limit, target) do
    case {budget_threshold(todays_budget, estimated_daily_limit), target} do
      {:red, :web} -> "text-red-600"
      {:yellow, :web} -> "text-yellow-600"
      {_, :web} -> "text-zinc-400"
      {:red, :swiftui} -> "color-red"
      {:yellow, :swiftui} -> "color-yellow"
      {_, :swiftui} -> "color-gray"
    end
  end

  defp budget_value_color(todays_budget, estimated_daily_limit, target) do
    case {budget_threshold(todays_budget, estimated_daily_limit), target} do
      {:red, :web} -> "text-red-600"
      {:yellow, :web} -> "text-yellow-600"
      {_, :web} -> "text-green-600"
      {:red, :swiftui} -> "color-red"
      {:yellow, :swiftui} -> "color-yellow"
      {_, :swiftui} -> "color-green"
    end
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

  defp maybe_trigger_monthly_transactions(user, date_string) when is_binary(date_string) do
    IO.inspect("Triggering monthly transactions for user #{user.id}, date: #{date_string}")

    target_date = Date.from_iso8601!(date_string)
    first_day_of_month = Porkybank.Utils.get_first_day_of_month(target_date)
    last_day_of_month = Porkybank.Utils.get_last_day_of_month(target_date)

    # Check if expenses already exist for this month
    query =
      from e in Porkybank.Banking.Expense,
        where:
          e.user_id == ^user.id and e.date >= ^first_day_of_month and e.date <= ^last_day_of_month

    existing_expenses = Porkybank.Repo.exists?(query)
    IO.inspect("Existing expenses for this month: #{existing_expenses}")

    # If no expenses exist for this month, trigger the monthly transactions job
    if not existing_expenses do
      IO.inspect("Triggering job!")

      result =
        Oban.insert(
          Porkybank.Workers.MonthlyTransactionsWorker.new(%{
            "target_date" => Date.to_iso8601(target_date)
          })
        )

      IO.inspect("Job result: #{inspect(result)}")
    else
      IO.inspect("Expenses already exist, not triggering job")
    end
  end

  defp maybe_trigger_monthly_transactions(_user, _), do: :ok
end
