defmodule LoggerFileBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logger_file_backend,
      version: "0.1.0",
      elixir: "~> 1.20",
      description: description(),
      docs: [main: "readme", extras: ["README.md", "LICENSE"]],
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :eex]]
  end

  defp description do
    "Simple logger backend that writes to a file"
  end

  defp package do
    [
      maintainers: ["Kurt Williams"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/onkel-dirtus/logger_file_backend"}
    ]
  end

  defp deps do
    [
      {:logger_backends, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end
end
