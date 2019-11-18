use Mix.Config

config :stonex, Stonex.Repo,
  username: "username",
  password: "password",
  database: "database",
  hostname: "hostname",
  show_sensitive_data_on_connection_error: true,
  pool_size: 5
