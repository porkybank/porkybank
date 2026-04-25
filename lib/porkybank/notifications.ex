defmodule Porkybank.Notifications do
  import Ecto.Query

  require Logger

  def send_daily_limit_sms(user, new_tx_count, today \\ Date.utc_today()) do
    phone_numbers =
      Porkybank.Accounts.PhoneNumber
      |> where(user_id: ^user.id)
      |> Porkybank.Repo.all()

    if phone_numbers == [] do
      :ok
    else
      daily_limit = calculate_daily_limit(user, today)
      formatted = Number.Currency.number_to_currency(daily_limit, unit: user.unit)
      message = "Porkybank: #{new_tx_count} new transaction#{if new_tx_count == 1, do: "", else: "s"}. Your daily limit is #{formatted}. https://porkybank.io"

      Enum.each(phone_numbers, fn %{number: number} ->
        Porkybank.TwilioClient.send_sms(number, message)
      end)
    end
  end

  defp calculate_daily_limit(user, today) do
    {:ok, %{total_spent: total_spent}} = Porkybank.PlaidClient.get_transactions(user, date: nil)

    income = case Porkybank.Incomes.get_income(user) do
      %{amount: amount} when not is_nil(amount) -> amount
      _ -> Decimal.new(0)
    end

    expenses = Porkybank.Expenses.list_expenses(user, today)

    monthly_expenses = Enum.reduce(expenses, Decimal.new(0), fn expense, total ->
      Decimal.add(expense.amount, total)
    end)

    total_remaining = Decimal.sub(income, Decimal.add(monthly_expenses, Decimal.from_float(total_spent)))

    days_in_month = Date.days_in_month(today)
    days_remaining = max(1, days_in_month - today.day)

    Decimal.div(total_remaining, days_remaining)
  end
end
