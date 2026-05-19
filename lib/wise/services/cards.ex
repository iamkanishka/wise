defmodule Wise.Services.Cards do
  @moduledoc "Wise Card API — card status, permissions, and sensitive data."
  alias Wise.Client

  @spec list(Wise.Config.t(), Wise.Types.profile_id(), keyword()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def list(config, profile_id, params \\ []),
    do: Client.get(config, "/v3/spend/profiles/#{profile_id}/cards", params)

  @spec get(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_token()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, profile_id, token),
    do: Client.get(config, "/v3/spend/profiles/#{profile_id}/cards/#{token}")

  @spec update_status(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.card_token(),
          String.t()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def update_status(config, profile_id, token, status) do
    Client.put(config, "/v3/spend/profiles/#{profile_id}/cards/#{token}/status", %{status: status})
  end

  @spec reset_pin_count(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_token()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def reset_pin_count(config, profile_id, token) do
    Client.post(config, "/v3/spend/profiles/#{profile_id}/cards/#{token}/reset-pin-count")
  end

  @spec get_spending_permissions(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.card_token()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_spending_permissions(config, profile_id, token) do
    Client.get(config, "/v3/spend/profiles/#{profile_id}/cards/#{token}/spending-permissions")
  end

  @spec update_single_permission(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.card_token(),
          String.t(),
          boolean()
        ) :: {:ok, map()} | {:error, Wise.Error.t()}
  def update_single_permission(config, profile_id, token, type, allowed) do
    Client.patch(
      config,
      "/v3/spend/profiles/#{profile_id}/cards/#{token}/spending-permissions",
      %{type: type, allowed: allowed}
    )
  end

  @spec update_spending_permissions(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.card_token(),
          map()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def update_spending_permissions(config, profile_id, token, perms) do
    Client.patch(
      config,
      "/v4/spend/profiles/#{profile_id}/cards/#{token}/spending-permissions",
      perms
    )
  end

  @spec get_encryption_key(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get_encryption_key(config),
    do: Client.get(config, "/twcard-data/v1/clientSideEncryption/fetchEncryptingKey")

  @spec get_sensitive_details(Wise.Config.t(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_sensitive_details(config, encrypted_payload) do
    Client.post(config, "/twcard-data/v1/sensitive-card-data/details", %{
      encryptedPayload: encrypted_payload
    })
  end

  @spec get_pin(Wise.Config.t(), String.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get_pin(config, encrypted_payload) do
    Client.post(config, "/twcard-data/v1/sensitive-card-data/pin", %{
      encryptedPayload: encrypted_payload
    })
  end
end
