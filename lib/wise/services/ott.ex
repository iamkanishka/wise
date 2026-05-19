defmodule Wise.Services.OTT do
  @moduledoc "Wise One Time Token API (deprecated — use SCA)."
  alias Wise.Client

  @spec status(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def status(config), do: Client.get(config, "/v1/one-time-token/status")
  @spec verify_pin(Wise.Config.t(), String.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def verify_pin(config, pin),
    do: Client.post(config, "/v1/one-time-token/pin/verify", %{pin: pin})

  @spec verify_face_map(Wise.Config.t(), String.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def verify_face_map(config, enc) do
    Client.post(config, "/v1/one-time-token/facemap/verify", %{faceMapEncrypted: enc})
  end

  @spec verify_device_fingerprint(Wise.Config.t(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def verify_device_fingerprint(config, token) do
    Client.post(config, "/v1/one-time-token/partner-device-fingerprint/verify", %{
      deviceToken: token
    })
  end

  @spec trigger_sms(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def trigger_sms(config), do: Client.post(config, "/v1/one-time-token/sms/trigger")
  @spec verify_sms(Wise.Config.t(), String.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def verify_sms(config, otp),
    do: Client.post(config, "/v1/one-time-token/sms/verify", %{otp: otp})

  @spec trigger_whatsapp(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def trigger_whatsapp(config), do: Client.post(config, "/v1/one-time-token/whatsapp/trigger")
  @spec verify_whatsapp(Wise.Config.t(), String.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def verify_whatsapp(config, otp),
    do: Client.post(config, "/v1/one-time-token/whatsapp/verify", %{otp: otp})

  @spec trigger_voice(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def trigger_voice(config), do: Client.post(config, "/v1/one-time-token/voice/trigger")
  @spec verify_voice(Wise.Config.t(), String.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def verify_voice(config, otp),
    do: Client.post(config, "/v1/one-time-token/voice/verify", %{otp: otp})

  @spec passed?(map()) :: boolean()
  def passed?(%{"challenges" => challenges}) do
    Enum.all?(challenges, fn c -> !c["required"] || c["passed"] end)
  end

  def passed?(_), do: false
end
