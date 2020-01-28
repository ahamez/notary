defmodule Notary.Router do
  @moduledoc false

  use Plug.Router
  use Plug.ErrorHandler

  require Logger

  plug(Plug.Logger)
  plug(Notary.Plug.VerifyRequest, builder_opts())
  plug(Notary.Plug.ReadPostBody)
  plug(:match)
  plug(:dispatch, builder_opts())

  get "/api/v1/public_key" do
    send_resp(conn, :ok, Notary.Sign.public_key(opts[:sign]))
  end

  post "/api/v1/sign" do
    signed = Notary.Sign.sign(opts[:sign], conn.assigns[:body])
    send_resp(conn, :ok, signed)
  end

  post "/api/v1/verify" do
    answer = Notary.Sign.verify(opts[:sign], conn.assigns[:body])
    send_resp(conn, :ok, "#{Atom.to_string(answer)}")
  end

  match _ do
    send_resp(conn, :not_found, "404")
  end

  defp handle_errors(conn, %{reason: reason}) do
    Logger.error("#{inspect(reason)}")
    message = Map.get(reason, :message, "N/A")
    send_resp(conn, conn.status, "#{message}")
  end
end
