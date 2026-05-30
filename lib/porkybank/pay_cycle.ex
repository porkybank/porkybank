defmodule Porkybank.PayCycle do
  def period_for(nil, today), do: {Date.beginning_of_month(today), Date.end_of_month(today)}
  def period_for("monthly", today), do: {Date.beginning_of_month(today), Date.end_of_month(today)}

  def period_for("semi_monthly", today) do
    if today.day < 15 do
      {Date.beginning_of_month(today), %{today | day: 14}}
    else
      {%{today | day: 15}, last_working_day(today)}
    end
  end

  def period_for(_, today), do: {Date.beginning_of_month(today), Date.end_of_month(today)}

  def periods_per_month("semi_monthly"), do: 2
  def periods_per_month(_), do: 1

  def last_working_day(date) do
    date |> Date.end_of_month() |> step_back_to_weekday()
  end

  defp step_back_to_weekday(date) do
    if Date.day_of_week(date) in [6, 7] do
      step_back_to_weekday(Date.add(date, -1))
    else
      date
    end
  end
end
