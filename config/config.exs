# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :porkybank,
  ecto_repos: [Porkybank.Repo]

# Configures the endpoint
config :porkybank, PorkybankWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PorkybankWeb.ErrorHTML, json: PorkybankWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Porkybank.PubSub,
  live_view: [signing_salt: "sb/4fMBe"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :porkybank, Porkybank.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import LiveView Native configuration
import_config "native.exs"

config :porkybank, Oban,
  repo: Porkybank.Repo,
  # Define your queues and concurrency
  queues: [default: 5, scheduled: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60},
    {Oban.Plugins.Cron,
     crontab: [
       {"@monthly", Porkybank.Workers.MonthlyTransactionsWorker}
     ]}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
