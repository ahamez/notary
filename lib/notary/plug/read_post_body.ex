defmodule Notary.Plug.ReadPostBody do
  @moduledoc false

  require Logger

  defmodule MaxLengthError do
    defexception message: "Max length", plug_status: 413
  end

  def init(options) do
    options
  end

  def call(conn = %Plug.Conn{method: "POST"}, _opts) do
    with {:ok, body, conn} <- read_body(conn) do
      Plug.Conn.assign(conn, :body, body)
    else
      _ -> raise MaxLengthError
    end
  end

  def call(conn = %Plug.Conn{}, _opts) do
    conn
  end

  # TODO Configurable max length
  defp read_body(conn) do
    case Plug.Conn.read_body(conn) do
      {atom, body, conn} ->
        do_read_body(<<>>, {atom, body, conn}, 32_000_000 - byte_size(body))

      _ ->
        raise MaxLengthError
    end
  end

  defp do_read_body(_, _, rem_len) when rem_len <= 0 do
    raise MaxLengthError
  end

  defp do_read_body(acc, {:ok, body, conn}, _) do
    {:ok, acc <> body, conn}
  end

  defp do_read_body(acc, {:more, partial_body, conn}, rem_len) do
    case Plug.Conn.read_body(conn) do
      {atom, body, conn} ->
        do_read_body(acc <> partial_body, {atom, body, conn}, rem_len - byte_size(body))

      _ ->
        raise MaxLengthError
    end
  end
end
