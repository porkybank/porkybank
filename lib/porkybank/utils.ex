defmodule Porkybank.Utils do
  def get_first_day_of_month(day) do
    day |> Date.beginning_of_month() |> Date.to_iso8601()
  end

  def get_last_day_of_month(day) do
    day |> Date.end_of_month() |> Date.to_iso8601()
  end
end
