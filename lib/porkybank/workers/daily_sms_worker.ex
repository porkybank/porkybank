defmodule Porkybank.Workers.DailySmsWorker do
  use Oban.Worker, queue: :scheduled, max_attempts: 3

  import Ecto.Query
  alias Porkybank.Repo

  @send_hour 8

  def perform(_args) do
    Repo.all(
      from u in Porkybank.Accounts.User,
        where: u.daily_sms_enabled == true,
        preload: [:phone_numbers]
    )
    |> Enum.filter(fn user ->
      user.phone_numbers != [] and morning_in_timezone?(user.timezone)
    end)
    |> Enum.each(fn user ->
      Porkybank.Notifications.send_daily_limit_sms(user, 0)
    end)

    :ok
  end

  defp morning_in_timezone?(nil), do: morning_in_timezone?("America/New_York")

  defp morning_in_timezone?(timezone) do
    case Timex.now(timezone) do
      %DateTime{hour: @send_hour} -> true
      _ -> false
    end
  end
end
