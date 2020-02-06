defmodule Notary.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    conf = configure()

    Logger.info("Listening on port #{conf.port}")

    children = [
      {Notary.Sign, secret: conf.secret, name: Notary.Sign},
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug:
          {Notary.Router,
           [
             max_post_length: conf.max_post_length,
             oidc: conf.oidc,
             oidc_provider: conf.oidc_provider,
             sign: Notary.Sign
           ]},
        port: conf.port
      ),
      {OpenIDConnect.Worker, conf.oidc}
    ]

    opts = [
      strategy: :one_for_one,
      name: Notary.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end

  defp configure() do
    max_post_length =
      case Application.fetch_env!(:notary, :max_post_length) do
        {:env, var, default} ->
          case var |> System.get_env(default) |> String.to_integer() do
            0 -> :inf
            max_post_length -> max_post_length
          end

        max_post_length ->
          max_post_length
      end

    if max_post_length < 0 do
      raise "Negative max_post_length"
    end

    oidc =
      case Application.get_env(:notary, :oidc) do
        {:env, var} -> var |> System.fetch_env!() |> read_oidc_json()
        oidc -> oidc
      end

    [oidc_provider] = Keyword.keys(oidc)

    port =
      case Application.fetch_env!(:notary, :http_port) do
        {:env, var, default} -> var |> System.get_env(default) |> String.to_integer()
        port -> port
      end

    secret =
      case Application.fetch_env!(:notary, :secret_key) do
        {:env, var} -> var |> System.fetch_env!() |> File.read!()
        secret -> secret
      end

    %{
      max_post_length: max_post_length,
      oidc: oidc,
      oidc_provider: oidc_provider,
      port: port,
      secret: secret
    }
  end

  # Build a keyword list for the OpenIDConnect library
  defp read_oidc_json(path) do
    json = path |> File.read!() |> Jason.decode!()
    provider = json |> Map.fetch!("provider") |> String.to_atom()

    # Build a keyword entry for a given atom
    entry = fn key ->
      {key, Map.fetch!(json, Atom.to_string(key))}
    end

    [
      {provider,
       [
         entry.(:discovery_document_uri),
         entry.(:client_id),
         entry.(:client_secret),
         entry.(:redirect_uri),
         entry.(:response_type),
         entry.(:scope)
       ]}
    ]
  end
end
