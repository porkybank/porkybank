defmodule Porkybank.Expenses do
  import Ecto.Query

  def get_expense(id) when is_binary(id) do
    Porkybank.Repo.get!(Porkybank.Banking.Expense, id) |> Porkybank.Repo.preload(:category)
  end

  def get_expense(nil) do
    %Porkybank.Banking.Expense{
      category: nil
    }
  end

  def delete_expense(id, user) do
    expense = Porkybank.Repo.get!(Porkybank.Banking.Expense, Ecto.UUID.cast!(id))

    if expense.user_id != user.id do
      raise "You are not allowed to delete this expense"
    end

    Porkybank.Repo.delete!(expense)
  end

  def list_expenses(user, date) do
    first_day_of_month = Porkybank.Utils.get_first_day_of_month(date)
    last_day_of_month = Porkybank.Utils.get_last_day_of_month(date)

    query =
      from e in Porkybank.Banking.Expense,
        order_by: [desc: e.amount],
        where:
          e.user_id == ^user.id and e.date >= ^first_day_of_month and e.date <= ^last_day_of_month,
        preload: [:category]

    Porkybank.Repo.all(query)
  end
end
