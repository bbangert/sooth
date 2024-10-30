defmodule Sooth.MixProject do
  use Mix.Project

  @version "0.5.0"
  @description "A minimal stochastic predictive model"

  def project do
    [
      app: :sooth,
      version: @version,
      name: "Sooth",
      description: @description,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      source_url: "https://github.com/bbangert/sooth"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:math, "~> 0.7.0"},
      {:typed_struct, "~> 0.3.0"},

      # Dev/test dependencies
      {:benchee, "~> 1.0", only: :dev},
      {:credo, "~> 1.7.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.1", only: :test},
      {:excoveralls, "~> 0.18.2", only: :test},
      {:ex_doc, "~> 0.34.2", only: :dev, runtime: false}
    ]
  end

  def docs do
    [
      main: "introduction",
      extras: ["guides/introduction.md"],
      groups_for_modules: [
        Api: [
          ~r/Sooth.Predictor/
        ],
        "Internal modules": [
          ~r/Sooth.Context/,
          ~r/Sooth.Statistic/
        ]
      ]
    ]
  end

  defp package do
    %{
      licenses: ["Unlicense"],
      maintainers: ["Ben Bangert"],
      links: %{"GitHub" => "https://github.com/bbangert/sooth"}
    }
  end

  defp dialyzer do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:mix]
    ]
  end
end
