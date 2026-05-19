defmodule Wise.Services.UserSecurity do
  @moduledoc "Wise User Security API — PIN, FaceMap, phone numbers, device fingerprints."
  alias Wise.Client

  @spec create_pin(Wise.Config.t(), Wise.Types.user_id(), String.t(), String.t()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def create_pin(config, user_id, pin, confirm_pin) do
    Client.post(config, "/v1/users/#{user_id}/pin", %{pin: pin, confirmPin: confirm_pin})
  end

  @spec enrol_face_map(Wise.Config.t(), Wise.Types.user_id(), String.t()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def enrol_face_map(config, user_id, encrypted) do
    Client.post(config, "/v1/users/#{user_id}/facemap", %{faceMapEncrypted: encrypted})
  end

  @spec create_phone_number(Wise.Config.t(), Wise.Types.user_id(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def create_phone_number(config, user_id, phone) do
    Client.post(config, "/v1/users/#{user_id}/phone-numbers", %{phoneNumber: phone})
  end

  @spec list_phone_numbers(Wise.Config.t(), Wise.Types.user_id()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def list_phone_numbers(config, user_id),
    do: Client.get(config, "/v1/users/#{user_id}/phone-numbers")

  @spec create_device_fingerprint(
          Wise.Config.t(),
          Wise.Types.user_id(),
          String.t(),
          String.t() | nil
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def create_device_fingerprint(config, user_id, token, name \\ nil) do
    body =
      %{deviceToken: token} |> then(fn b -> if name, do: Map.put(b, :name, name), else: b end)

    Client.post(config, "/v1/users/#{user_id}/device-fingerprints", body)
  end
end
