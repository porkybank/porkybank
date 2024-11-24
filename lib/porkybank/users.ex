defmodule Porkybank.Users do
  def skip_plaid(user) do
    user
    |> Ecto.Changeset.change(%{
      opted_out_of_plaid_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })
    |> Porkybank.Repo.update()
  end
end
