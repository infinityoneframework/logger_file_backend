import Config

config :logger, level: :info

config :logger, :dev_backend,
  level: :error,
  path: "test/logs/error.log",
  format: "DEV $message"
