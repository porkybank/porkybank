defmodule Porkybank.DataMigrations do
  import Ecto.Query

  def run() do
    # delete all transactions where month is january 2024
    date = Date.from_iso8601!("2023-08-01")
    first_day_of_month = date |> Date.beginning_of_month() |> Date.to_iso8601()
    last_day_of_month = date |> Date.end_of_month() |> Date.to_iso8601()

    Porkybank.Repo.delete_all(
      from t in Porkybank.Banking.PlaidTransaction,
        where: t.date >= ^first_day_of_month and t.date <= ^last_day_of_month
    )
  end
end
