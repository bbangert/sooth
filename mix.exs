defmodule Sooth.MixProject do
  use Mix.Project

  @version "0.2.0"
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
      package: package(),
      test_coverage: [tool: ExCoveralls],
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
      {:aja, "~> 0.7.0"},
      {:math, "~> 0.7.0"},
      {:typed_struct, "~> 0.3.0"},

      # Dev/test dependencies
      {:stream_data, "~> 1.1", only: :test},
      {:excoveralls, "~> 0.18.2", only: :test},
      {:ex_doc, "~> 0.34.2", only: :dev, runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["Unlicense"],
      maintainers: ["Ben Bangert"],
      links: %{"GitHub" => "https://github.com/bbangert/sooth"}
    }
  end
end
