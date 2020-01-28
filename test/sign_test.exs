defmodule Notary.SignTest do
  use ExUnit.Case, async: true

  setup do
    %{public: public, secret: secret} = :enacl.sign_keypair()
    sign_server = start_supervised!({Notary.Sign, [secret: secret]})
    %{sign_server: sign_server, public: public}
  end

  test "retrieve public key", %{sign_server: sign_server, public: public} do
    assert Notary.Sign.public_key(sign_server) == public
  end

  test "verify signed data", %{sign_server: sign_server} do
    Enum.each(0..127, fn len ->
      data = generate_random_data(len)
      signed = Notary.Sign.sign(sign_server, data)
      assert Notary.Sign.verify(sign_server, signed) == :ok
    end)
  end

  test "verify non signed data", %{sign_server: sign_server} do
    Enum.each(0..127, fn len ->
      data = generate_random_data(len)
      assert Notary.Sign.verify(sign_server, data) == :error
    end)
  end

  defp generate_random_data(len) do
    # Printable ASCII characters
    "#{Enum.take_random(?!..?~, len)}"
  end
end
