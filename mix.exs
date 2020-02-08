defmodule Notary.MixProject do
  use Mix.Project

  def project do
    [
      app: :notary,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Notary.Application, []}
    ]
  end

  defp deps do
    [
      {:enacl, "~> 1.0.0"},
      {:openid_connect, "~> 0.1"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
