defmodule Porkybank.Incomes do
  def get_income(user) do
    if income = Porkybank.Repo.get_by(Porkybank.Banking.Income, user_id: user.id) do
      income
    else
      %Porkybank.Banking.Income{}
    end
  end
end
