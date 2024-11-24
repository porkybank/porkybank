defmodule Porkybank.OpenAI do
  use Tesla

  require Logger

  import Ecto.Query

  plug Tesla.Middleware.BaseUrl, "https://api.openai.com/v1"
  plug Tesla.Middleware.JSON

  plug Tesla.Middleware.Headers, [
    {"Authorization",
     "Bearer #{Application.compile_env!(:porkybank, Porkybank.OpenAI, :api_key)}"},
    {"Content-Type", "application/json"}
  ]

  def match_new_transactions_with_recurring_transactions(user, transaction_ids, today) do
    Logger.info(
      "OpenAI: Matching new transactions with recurring transactions for user #{user.id}"
    )

    monthly_expenses = Porkybank.Expenses.list_expenses(user, today)

    new_transactions =
      Porkybank.Banking.PlaidTransaction
      |> where([t], t.id in ^transaction_ids)
      |> Porkybank.Repo.all()

    system_prompt = create_system_prompt()
    user_prompt = create_user_prompt(new_transactions, monthly_expenses)

    Logger.info("OpenAI: User prompt: #{inspect(user_prompt)}")

    case post("/chat/completions", %{
           model: "gpt-4o-mini",
           response_format: %{type: "json_object"},
           messages: [
             %{role: "system", content: system_prompt},
             %{role: "user", content: user_prompt}
           ]
         }) do
      {:ok, resp = %{body: %{"choices" => choices}}} ->
        first_choice = List.first(choices)
        matches = first_choice["message"]["content"]
        Logger.info("OpenAI response (matches): #{inspect(matches)}")

        resp

      {:ok, resp} ->
        Logger.info("OpenAI error: #{inspect(resp)}")
        resp

      {:error, reason} ->
        Logger.error("OpenAI error: #{inspect(reason)}")
        reason
    end
  end

  defp create_user_prompt(new_transactions, monthly_expenses) do
    monthly_expenses_formatted =
      Enum.map(monthly_expenses, fn expense ->
        %{
          name: expense.description,
          category: expense.category.name,
          amount: expense.amount,
          date: expense.date,
          id: expense.id
        }
      end)

    new_transactions_formatted =
      Enum.map(new_transactions, fn transaction ->
        %{
          name: transaction.name,
          amount: transaction.amount,
          date: transaction.date,
          transaction_id: transaction.transaction_id
        }
      end)

    """
    New transactions: #{Jason.encode!(new_transactions_formatted)}
    Monthly recurring expenses: #{Jason.encode!(monthly_expenses_formatted)}
    """
  end

  defp create_system_prompt() do
    """
      Given a list of "New transactions" and a list of "Monthly recurring expenses", identify which of the "New transactions" match any of the "Monthly recurring expenses". Respond with only the matching new transactions in JSON format. The match should be based on similar names and amounts, allowing for small variations. Sometimes "New transactions" can be half the amount of the recurring expense because they are paid bi-monthly. In this case, the system should still match them.

      Include the full details of the matching "New transaction" in the response, do not include the monthly recurring expense details besides the matched_expense_id. confidence_score should be determined by you (LOW, MED, HIGH).

      {"matching_transactions: [{"name": transaction_name, "amount": transaction_amount, "date": transaction_date, "transaction_id": transaction_id, "matched_expense_id": expense_id, "confidence_score": confidence_score}]}
    """
  end
end
