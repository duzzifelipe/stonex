use Mix.Config

# Configure your database
config :stonex, Stonex.Repo,
  username: "postgres",
  password: "postgres",
  database: "stonex_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :stonex, StonexWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Create weak passwords for testing
# to minimize compute work needed
config :bcrypt_elixir, :log_rounds, 1

import_config "test.secret.exs"
