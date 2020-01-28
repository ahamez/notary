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
      # Waiting for next release. We need master for crypto_sign_ed25519_sk_to_pk/1.
      # {:enacl, "~> 0.17.2"},
      {:enacl, github: "jlouis/enacl", commit: "fc943a19c7527c6af7f2ece948b42dcc1f2882d4"},
      {:openid_connect, "~> 0.1"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
