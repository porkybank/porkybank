defmodule Porkybank.Workers.MonthlyTransactionsWorker do
  require Logger
  use Oban.Worker, queue: :scheduled, max_attempts: 3

  import Ecto.Query

  alias Porkybank.Repo

  def perform(_args) do
    today = Date.utc_today()
    last_month = Timex.shift(today, months: -1)
    prev_month_beginning = last_month |> Date.beginning_of_month()
    prev_month_end = last_month |> Date.end_of_month()

    expenses =
      Repo.all(
        from e in Porkybank.Banking.Expense,
          where: e.date >= ^prev_month_beginning and e.date <= ^prev_month_end,
          preload: [:category]
      )

    case Repo.transaction(fn ->
           Repo.insert_all(
             Porkybank.Banking.Expense,
             Enum.map(
               expenses,
               &%{
                 amount: &1.amount,
                 category_id: &1.category_id,
                 description: &1.description,
                 date:
                   &1.date
                   |> Timex.shift(months: 1)
                   |> Timex.to_date(),
                 user_id: &1.user_id,
                 inserted_at:
                   Timex.now() |> Timex.to_naive_datetime() |> NaiveDateTime.truncate(:second),
                 updated_at:
                   Timex.now() |> Timex.to_naive_datetime() |> NaiveDateTime.truncate(:second)
               }
             )
           )

           {:ok, "Expenses moved successfully"}
         end) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.error("Error while moving expenses: #{inspect(error)}")
        :error
    end
  end
end
