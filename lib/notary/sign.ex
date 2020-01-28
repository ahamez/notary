defmodule Notary.Sign do
  @moduledoc false

  use GenServer
  require Logger

  ## Client API

  def start_link(opts) do
    {secret, opts} = Keyword.pop!(opts, :secret)
    GenServer.start_link(__MODULE__, secret, opts)
  end

  def public_key(server) do
    GenServer.call(server, :public_key)
  end

  def sign(server, data) do
    GenServer.call(server, {:sign, data})
  end

  def verify(server, data) do
    GenServer.call(server, {:verify, data})
  end

  ## GenServer Callbacks

  @impl true
  def init(secret) do
    case :enacl.verify() do
      :ok ->
        public = :enacl.crypto_sign_ed25519_sk_to_pk(secret)
        {:ok, %{secret: secret, public: public}}

      :error ->
        Logger.error("Unable to verify :enacl")
        {:stop, :cannot_verify_enacl}
    end
  end

  @impl true
  def handle_call(:public_key, _from, state = %{public: public}) do
    {:reply, public, state}
  end

  @impl true
  def handle_call({:sign, data}, _from, state = %{secret: secret}) do
    {:reply, :enacl.sign(data, secret), state}
  end

  @impl true
  def handle_call({:verify, data}, _from, state = %{public: public}) do
    answer =
      case :enacl.sign_open(data, public) do
        {:ok, _} -> :ok
        {:error, _} -> :error
      end

    {:reply, answer, state}
  end
end
