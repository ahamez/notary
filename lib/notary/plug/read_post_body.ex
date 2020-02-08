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
      _ ->
        raise MaxLengthError
    end
  end

  def call(conn = %Plug.Conn{}, _opts) do
    conn
  end

  defp read_body(conn, :inf) do
    case Plug.Conn.read_body(conn) do
      {atom, partial_body, conn} ->
        Logger.debug("Read #{byte_size(partial_body)} bytes")
        do_read_inf_body(partial_body, atom, conn)

      _ ->
        raise MaxLengthError
    end
  end

  defp read_body(conn, max_length) do
    case Plug.Conn.read_body(conn) do
      {atom, partial_body, conn} ->
        Logger.debug("Read #{byte_size(partial_body)} bytes")
        do_read_body(partial_body, atom, conn, max_length - byte_size(partial_body))

      _ ->
        raise MaxLengthError
    end
  end

  defp do_read_inf_body(acc, :ok, conn) do
    {:ok, acc, conn}
  end

  defp do_read_inf_body(acc, :more, conn) do
    case Plug.Conn.read_body(conn) do
      {atom, partial_body, conn} ->
        Logger.debug("Read #{byte_size(partial_body)} bytes")
        do_read_inf_body([acc, partial_body], atom, conn)

      _ ->
        raise MaxLengthError
    end
  end

  defp do_read_body(_acc, _atom, _conn, rem_len) when rem_len <= 0 do
    raise MaxLengthError
  end

  defp do_read_body(acc, :ok, conn, _rem_len) do
    {:ok, acc, conn}
  end

  defp do_read_body(acc, :more, conn, rem_len) do
    case Plug.Conn.read_body(conn) do
      {atom, partial_body, conn} ->
        Logger.debug("Read #{byte_size(partial_body)} bytes")
        do_read_body([acc, partial_body], atom, conn, rem_len - byte_size(partial_body))

      _ ->
        raise MaxLengthError
    end
  end
end
