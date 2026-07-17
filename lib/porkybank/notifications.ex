defmodule Porkybank.Notifications do
  import Ecto.Query

  require Logger

  def send_transaction_modified_sms(user, action) when action in [:ignored, :included] do
    phone_numbers =
      Porkybank.Accounts.PhoneNumber
      |> where(user_id: ^user.id)
      |> Porkybank.Repo.all()

    if phone_numbers == [] do
      :ok
    else
      today = Date.utc_today()
      {daily_limit, total_remaining} = calculate_daily_limit(user, today)
      action_text = if action == :ignored, do: "ignored", else: "included"

      message =
        if Decimal.negative?(total_remaining) do
          formatted = Number.Currency.number_to_currency(Decimal.abs(total_remaining), unit: user.unit)
          "Porkybank: Transaction #{action_text}. Budget exceeded by #{formatted}. https://porkybank.io"
        else
          formatted = Number.Currency.number_to_currency(daily_limit, unit: user.unit)
          "Porkybank: Transaction #{action_text}. Your daily limit is now #{formatted}. https://porkybank.io"
        end

      Enum.each(phone_numbers, fn %{number: number} ->
        Porkybank.TwilioClient.send_sms(number, message)
      end)
    end
  end

  def send_morning_sms(user, today \\ Date.utc_today()) do
    phone_numbers =
      Porkybank.Accounts.PhoneNumber
      |> where(user_id: ^user.id)
      |> Porkybank.Repo.all()

    if phone_numbers == [] do
      :ok
    else
      {daily_limit, total_remaining} = calculate_daily_limit(user, today)

      message =
        if Decimal.negative?(total_remaining) do
          formatted = Number.Currency.number_to_currency(Decimal.abs(total_remaining), unit: user.unit)
          "Porkybank: Good morning! Budget exceeded by #{formatted}. https://porkybank.io"
        else
          formatted = Number.Currency.number_to_currency(daily_limit, unit: user.unit)
          "Porkybank: Good morning! Your daily budget is #{formatted}. https://porkybank.io"
        end

      Enum.each(phone_numbers, fn %{number: number} ->
        Porkybank.TwilioClient.send_sms(number, message)
      end)
    end
  end

  def send_test_sms_notification(user, number, today \\ Date.utc_today()) do
    {daily_limit, _total_remaining} = calculate_daily_limit(user, today)
    formatted = Number.Currency.number_to_currency(daily_limit, unit: user.unit)
    message = "Porkybank: Testing SMS notification. Your daily budget is #{formatted}. https://porkybank.io"
    Porkybank.TwilioClient.send_sms(number, message)
  end

  def send_daily_limit_sms(user, new_tx_count, today \\ Date.utc_today()) do
    phone_numbers =
      Porkybank.Accounts.PhoneNumber
      |> where(user_id: ^user.id)
      |> Porkybank.Repo.all()

    if phone_numbers == [] do
      :ok
    else
      {daily_limit, total_remaining} = calculate_daily_limit(user, today)
      tx_text = "#{new_tx_count} new transaction#{if new_tx_count == 1, do: "", else: "s"}"

      message =
        if Decimal.negative?(total_remaining) do
          formatted = Number.Currency.number_to_currency(Decimal.abs(total_remaining), unit: user.unit)
          "Porkybank: #{tx_text}. Budget exceeded by #{formatted}. https://porkybank.io"
        else
          formatted = Number.Currency.number_to_currency(daily_limit, unit: user.unit)
          "Porkybank: #{tx_text}. Your daily limit is #{formatted}. https://porkybank.io"
        end

      Enum.each(phone_numbers, fn %{number: number} ->
        Porkybank.TwilioClient.send_sms(number, message)
      end)
    end
  end

  defp calculate_daily_limit(user, today) do
    pay_cycle = user.pay_cycle
    {period_start, period_end} = Porkybank.PayCycle.period_for(pay_cycle, today)
    periods = Porkybank.PayCycle.periods_per_month(pay_cycle)

    {:ok, %{total_spent: total_spent, today_spent: today_spent}} =
      Porkybank.PlaidClient.get_transactions(user, date: nil, period_start: period_start)

    income =
      case Porkybank.Incomes.get_income(user) do
        %{amount: amount} when not is_nil(amount) -> amount
        _ -> Decimal.new(0)
      end

    expenses = Porkybank.Expenses.list_expenses(user, today)

    monthly_expenses =
      Enum.reduce(expenses, Decimal.new(0), fn expense, total ->
        Decimal.add(expense.amount, total)
      end)

    period_income = Decimal.div(income, periods)
    period_expenses = Decimal.div(monthly_expenses, periods)

    total_remaining =
      Decimal.sub(period_income, Decimal.add(period_expenses, Decimal.from_float(total_spent)))

    days_remaining = max(1, Date.diff(period_end, today))

    # Mirror Today's Budget from the overview: amortize spending before today
    # across the remaining days, then subtract today's spending dollar-for-dollar
    # and floor at 0. This keeps the SMS daily limit in sync with the app.
    spent_before_today =
      Decimal.sub(Decimal.from_float(total_spent), Decimal.from_float(today_spent))

    remaining_before_today =
      Decimal.sub(period_income, Decimal.add(period_expenses, spent_before_today))

    todays_budget =
      Decimal.max(
        Decimal.new(0),
        Decimal.sub(
          Decimal.div(remaining_before_today, days_remaining),
          Decimal.from_float(today_spent)
        )
      )

    {todays_budget, total_remaining}
  end
end
