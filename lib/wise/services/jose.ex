defmodule Wise.Services.JOSE do
  @moduledoc "Wise JOSE (JWS/JWE) key management and playground."
  alias Wise.Client

  @spec get_response_public_keys(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get_response_public_keys(config),
    do: Client.get(config, "/v1/auth/jose/response/public-keys")

  @spec register_request_public_key(Wise.Config.t(), map()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def register_request_public_key(config, key) do
    Client.post(config, "/v1/auth/jose/request/public-keys", %{publicKey: key})
  end

  @spec playground_verify_jws(Wise.Config.t(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def playground_verify_jws(config, token),
    do: Client.post(config, "/v1/auth/jose/playground/jws", %{token: token})

  @spec playground_get_jwe(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def playground_get_jwe(config), do: Client.get(config, "/v1/auth/jose/playground/jwe")
  @spec playground_encrypt_jwe(Wise.Config.t(), map()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def playground_encrypt_jwe(config, payload),
    do: Client.post(config, "/v1/auth/jose/playground/jwe", payload)

  @spec playground_encrypt_jwe_direct(Wise.Config.t(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def playground_encrypt_jwe_direct(config, payload) do
    Client.post(config, "/v1/auth/jose/playground/jwe-direct-encryption", payload)
  end

  @spec playground_encrypt_jws_jwe(Wise.Config.t(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def playground_encrypt_jws_jwe(config, payload),
    do: Client.post(config, "/v1/auth/jose/playground/jwsjwe", payload)
end
