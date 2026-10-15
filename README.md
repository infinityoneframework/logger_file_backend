# LoggerFileBackend

A `LoggerBackends` backend that writes logs to files, filters metadata, and
optionally rotates files by size. It also reopens a log after an external rename.
Rename detection relies on Unix inodes and is not supported on Windows.

## Elixir 1.20 setup

This fork targets Elixir 1.20 and Erlang/OTP 29. The `.tool-versions` file selects
Elixir 1.20.4 and Erlang 29.1.2.

Elixir's `Logger.add_backend/2`, `Logger.configure_backend/2`, and
`config :logger, backends: ...` are deprecated. This project depends on
[`logger_backends`](https://hexdocs.pm/logger_backends/LoggerBackends.html)
to retain the existing backend protocol and configuration options.

Add this fork to your application's dependencies. Mix automatically starts its
runtime dependencies, including `:logger_backends`.

Configure each named file in `config/config.exs`:

```elixir
import Config

config :logger, :error_log,
  path: "/var/log/my_app/error.log",
  level: :error,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  rotate: %{max_bytes: 10_000_000, keep: 5}
```

Register the backend in your application's `start/2` callback, after the Logger
and LoggerBackends applications have started, before starting children that log:

```elixir
{:ok, _pid} = LoggerBackends.add({LoggerFileBackend, :error_log})
```

Do not call this from a configuration file. The `:logger_backends` application
must be running first. Remove the old `config :logger, backends: ...` registration
when migrating so the backend is not installed twice. Register each file once.

The default console handler remains independently configurable:

```elixir
config :logger, level: :debug
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
```

The global Logger level also filters messages before they reach this backend.
For example, a backend at `:debug` cannot receive debug messages if the global
level is `:info`. Set `config :logger, default_handler: false` when you want to
turn off the default console handler.

## Options

- `:path` — destination file; `nil` disables file output and closes the file.
- `:level` — minimum level; `nil` accepts every level delivered to the backend.
- `:format` — Logger format string or `{module, function}` formatter; defaults to
  `"$time $metadata[$level] $message\n"`.
- `:metadata` — ordered metadata keys to display, or `:all`; defaults to `[]`.
- `:metadata_filter` — required metadata key/value pairs; defaults to no filter.
- `:rotate` — `%{max_bytes: positive_integer, keep: positive_integer}`, or `nil`.
  Before writing a message, a file at or above `max_bytes` is renamed to `.1`;
  older archives move up to `.keep`. A message may take the file above the limit.

Backend formatting stays in the named backend configuration. The
`:default_formatter` configuration applies to the default handler, not this file.
The compatibility bridge preserves legacy event levels: warning is formatted as
`warn`, notice as `info`, and critical/alert/emergency as `error`.

## Runtime configuration

```elixir
{:ok, _pid} = LoggerBackends.add({LoggerFileBackend, :debug_log})

:ok = LoggerBackends.configure({LoggerFileBackend, :debug_log},
  path: "/var/log/my_app/debug.log",
  level: :debug,
  metadata: [:user_id],
  metadata_filter: [device: 1]
)

Logger.info("device connected", device: 1, user_id: 42)
Logger.flush()

:ok = LoggerBackends.remove({LoggerFileBackend, :debug_log}, flush: true)
```

Changing the path closes the old file immediately. Removing the backend closes
its file. Backend settings remain under `Application.get_env(:logger, name)` so
an explicitly re-added backend uses its last configuration.

## Multiple files

Use separate names and register both backends during application startup:

```elixir
config :logger, :info_log, path: "/var/log/my_app/info.log", level: :info
config :logger, :error_log, path: "/var/log/my_app/error.log", level: :error
```

```elixir
{:ok, _pid} = LoggerBackends.add({LoggerFileBackend, :info_log})
{:ok, _pid} = LoggerBackends.add({LoggerFileBackend, :error_log})
```

An error reaches both files because `:level` is a minimum threshold.

## Development

Run `mix deps.get`, `mix test --warnings-as-errors`, and `mix test --cover`.
Tests use isolated temporary directories and flush Logger before assertions.
File-descriptor checks use `lsof` and require a Unix environment, matching the
supported external-rotation platform.

Development config defines `:dev_backend` options. Register it explicitly with
`LoggerBackends.add({LoggerFileBackend, :dev_backend})` in `iex -S mix` to try it.
Generate documentation with `mix docs --warnings-as-errors`.

## License

Copyright Kurt Williams. Distributed under the MIT license; see [LICENSE](LICENSE).
