defmodule Porkybank.IgnoredTransactions do
  use Ecto.Schema

  def create(transaction_id, user, opts \\ []) do
    opts = Keyword.merge([matched_expense_id: nil, reason: "Manually ignored"], opts)

    Porkybank.Banking.IgnoredTransaction.changeset(%Porkybank.Banking.IgnoredTransaction{}, %{
      transaction_id: transaction_id,
      matched_expense_id: opts[:matched_expense_id],
      reason: opts[:reason]
    })
    |> Ecto.Changeset.change(%{user_id: user.id})
    |> Porkybank.Repo.insert()
  end

  def delete(id, user) do
    ignored_transaction =
      Porkybank.Banking.IgnoredTransaction
      |> Porkybank.Repo.get_by(transaction_id: id)

    if ignored_transaction.user_id != user.id do
      raise "You are not allowed to delete this ignored transaction"
    end

    Porkybank.Repo.delete!(ignored_transaction)
  end
end
