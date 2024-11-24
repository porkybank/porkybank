defmodule Porkybank.Repo do
  use Ecto.Repo,
    otp_app: :porkybank,
    adapter: Ecto.Adapters.Postgres
end
