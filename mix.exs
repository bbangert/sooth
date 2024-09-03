defmodule Sooth.MixProject do
  use Mix.Project

  def project do
    [
      app: :sooth,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:typed_struct, "~> 0.3.0"},
      {:stream_data, "~> 1.1", only: :test}
    ]
  end
end
