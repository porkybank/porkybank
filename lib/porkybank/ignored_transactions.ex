defmodule Porkybank.IgnoredTransactions do
  use Ecto.Schema

  def create(transaction_id, user) do
    Porkybank.Banking.IgnoredTransaction.changeset(%Porkybank.Banking.IgnoredTransaction{}, %{
      transaction_id: transaction_id,
      reason: "Manually ignored"
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
