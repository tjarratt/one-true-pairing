# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :one_true_pairing,
  ecto_repos: [OneTruePairing.Repo],
  basic_auth_password: System.fetch_env!("BASIC_AUTH_PASSWORD")

# Configures the endpoint
config :one_true_pairing, OneTruePairingWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: OneTruePairingWeb.ErrorHTML, json: OneTruePairingWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: OneTruePairing.PubSub,
  live_view: [signing_salt: "3uYA8M/T"]

config :error_tracker,
  repo: OneTruePairing.Repo,
  otp_app: :one_true_pairing

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :one_true_pairing, OneTruePairing.Mailer, adapter: Swoosh.Adapters.Local

# Configure our pair shuffling algorithm
# Should be overridden by test to reduce randomness
config :one_true_pairing, shuffler: &OneTruePairing.Pairing.shuffle/1

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.19.12",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.1",
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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
