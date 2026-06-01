defmodule Porkybank.PayCycle do
  def period_for(nil, today), do: {Date.beginning_of_month(today), Date.end_of_month(today)}
  def period_for("monthly", today), do: {Date.beginning_of_month(today), Date.end_of_month(today)}

  def period_for("semi_monthly", today) do
    lwd = last_working_day(today)

    cond do
      today.day < 15 ->
        # Period starts the day after the previous month's last working day
        prev_month_end = Date.add(Date.beginning_of_month(today), -1)
        prev_lwd = last_working_day(prev_month_end)
        {Date.add(prev_lwd, 1), %{today | day: 14}}

      Date.compare(today, lwd) != :gt ->
        {%{today | day: 15}, lwd}

      true ->
        # After last working day (e.g. May 30/31): period starts day after last working day
        next_month = Date.add(Date.end_of_month(today), 1)
        {Date.add(lwd, 1), %{next_month | day: 14}}
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
