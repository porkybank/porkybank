defmodule Porkybank.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Logger.add_backend(Sentry.LoggerBackend)

    children = [
      # Start the Telemetry supervisor
      PorkybankWeb.Telemetry,
      # Start the Ecto repository
      Porkybank.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Porkybank.PubSub},
      # Start Finch
      {Finch, name: Porkybank.Finch},
      # Start the Endpoint (http/https)
      PorkybankWeb.Endpoint,
      # Start a worker by calling: Porkybank.Worker.start_link(arg)
      # {Porkybank.Worker, arg}
      {Oban, Application.fetch_env!(:porkybank, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Porkybank.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PorkybankWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
