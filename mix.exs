defmodule Gemini.MixProject do
  use Mix.Project

  def project do
    [
      app: :gemini,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Gemini",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :jason, :tesla]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.5"},
      {:jason, "~> 1.4"},
      {:hackney, "~> 1.18"},
      {:httpoison, "~> 2.0", only: :test},
      {:bypass, "~> 2.1", only: :test},
      {:meck, "~> 0.9.2", only: :test},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Elixir client library for Google's Gemini AI API.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/username/gemini"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
