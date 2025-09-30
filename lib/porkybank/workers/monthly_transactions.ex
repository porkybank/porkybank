defmodule Porkybank.Workers.MonthlyTransactionsWorker do
  require Logger
  use Oban.Worker, queue: :scheduled, max_attempts: 3

  import Ecto.Query
  alias Porkybank.Repo

  # Handle both cases: with target_date and without
  def perform(%{args: %{"target_date" => target_date_string}}) do
    target_date = Date.from_iso8601!(target_date_string)
    copy_expenses_to_month(target_date)
  end

  def perform(_args) do
    # Default behavior for cron job - copy to current month
    today = Date.utc_today()
    copy_expenses_to_month(today)
  end

  defp copy_expenses_to_month(target_date) do
    previous_month = Timex.shift(target_date, months: -1)
    prev_month_beginning = previous_month |> Date.beginning_of_month()
    prev_month_end = previous_month |> Date.end_of_month()

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
                 expense_alias: &1.expense_alias,
                 date: target_date |> Date.beginning_of_month(),
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
