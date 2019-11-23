# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :stonex,
  ecto_repos: [Stonex.Repo]

# Configures the endpoint
config :stonex, StonexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1mZH2dWAVMcmFN0YUxkMSeFbODtjsVuZ2Pj8s0iKNGAnzPQXvHCVxhoG/3SF8wzt",
  render_errors: [view: StonexWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Stonex.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# JWT library
config :stonex, Stonex.Users.Guardian,
  issuer: "stonex",
  secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
