defmodule Porkybank.Categories do
  import Ecto.Query

  alias Porkybank.Repo

  def get_categories(user_id) do
    categories =
      Repo.all(Porkybank.Banking.CustomPfc) ++
        Repo.all(
          from c in Porkybank.Banking.Category,
            where: c.user_id == ^user_id or is_nil(c.user_id)
        )

    Enum.sort_by(categories, &(&1.description || &1.name))
  end
end
