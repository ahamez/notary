defmodule Notary.Plug.VerifyRequest do
  @moduledoc false

  require Logger

  defmodule UnauthorizedRequestError do
    defexception message: "Unauthorized request", plug_status: 403
  end

  def init(opts) do
    opts
  end

  def call(conn = %Plug.Conn{request_path: "/health"}, _opts) do
    conn
  end

  def call(conn, opts) do
    with {:ok, auth} <- get_auth_header(conn),
         :ok <- verify(auth, opts[:oidc_provider]) do
      conn
    else
      _ -> raise UnauthorizedRequestError
    end
  end

  defp get_auth_header(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      [h] -> {:ok, h}
      _ -> {:error, :no_auth_header}
    end
  end

  defp verify(token, provider) do
    try do
      token = String.replace_leading(token, "Bearer ", "")

      case OpenIDConnect.verify(provider, token) do
        {:ok, claims} ->
          Logger.debug("#{inspect(claims)}")
          {:ok, token_exp} = DateTime.from_unix(claims["exp"])

          case DateTime.compare(DateTime.utc_now(), token_exp) do
            :gt ->
              Logger.info("Expired token for #{claims["preferred_username"]}")
              {:error, :expired_token}

            _ ->
              Logger.info("Valid token for #{claims["preferred_username"]}")
              :ok
          end

        _ ->
          Logger.info("Invalid token #{inspect(token)}")
          {:error, :cannot_verify}
      end
    rescue
      _ -> {:error, :cannot_verify}
    end
  end
end
