defmodule Notary.Plug.ReadPostBody do
  @moduledoc false

  require Logger

  defmodule MaxLengthError do
    defexception message: "Max length", plug_status: 413
  end

  def init(opts) do
    opts
  end

  def call(conn = %Plug.Conn{method: "POST"}, opts) do
    with {:ok, body, conn} <- read_body(conn, opts[:max_post_length]) do
      Plug.Conn.assign(conn, :body, body)
    else
      _ -> raise MaxLengthError
    end
  end

  def call(conn = %Plug.Conn{}, _opts) do
    conn
  end

  defp read_body(conn, rem_len) do
    do_read_body(<<>>, :more, conn, rem_len)
  end

  defp do_read_body(acc, :ok, conn, :inf) do
    {:ok, acc, conn}
  end

  defp do_read_body(_acc, _atom, _conn, rem_len) when rem_len <= 0 do
    {:error, :max_length}
  end

  defp do_read_body(acc, :ok, conn, _rem_len) do
    {:ok, acc, conn}
  end

  defp do_read_body(acc, :more, conn, rem_len) do
    case Plug.Conn.read_body(conn) do
      {atom, body, conn} ->
        Logger.debug("Read #{byte_size(body)} bytes")

        case rem_len do
          :inf ->
            do_read_body([acc, body], atom, conn, :inf)

          rem_len ->
            do_read_body([acc, body], atom, conn, rem_len - byte_size(body))
        end

      _ ->
        {:error, :read_error}
    end
  end
end
