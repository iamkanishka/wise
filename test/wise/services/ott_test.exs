defmodule Wise.Services.OTTTest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Wise.Services.OTT

  @passed %{
    "expiresAt" => "2024-01-01T01:00:00Z",
    "challenges" => [%{"type" => "PIN", "required" => true, "passed" => true}]
  }
  @pending %{
    "expiresAt" => "2024-01-01T01:00:00Z",
    "challenges" => [
      %{"type" => "SMS", "required" => true, "passed" => false, "otpId" => "otp-1"}
    ]
  }

  setup do
    {bypass, config} = setup_bypass()
    %{bypass: bypass, config: config}
  end

  test "status/1 fetches OTT state", %{bypass: b, config: c} do
    stub_get(b, "/v1/one-time-token/status", @passed)
    assert {:ok, s} = OTT.status(c)
    assert length(s["challenges"]) == 1
  end

  test "trigger_sms/1 triggers SMS challenge", %{bypass: b, config: c} do
    stub_post(b, "/v1/one-time-token/sms/trigger", @pending)
    assert {:ok, s} = OTT.trigger_sms(c)
    assert hd(s["challenges"])["otpId"] == "otp-1"
  end

  test "verify_sms/2 verifies OTP", %{bypass: b, config: c} do
    stub_post(b, "/v1/one-time-token/sms/verify", @passed)
    assert {:ok, s} = OTT.verify_sms(c, "123456")
    assert OTT.passed?(s)
  end

  test "trigger_whatsapp/1 triggers WhatsApp challenge", %{bypass: b, config: c} do
    stub_post(b, "/v1/one-time-token/whatsapp/trigger", @pending)
    assert {:ok, _} = OTT.trigger_whatsapp(c)
  end

  test "trigger_voice/1 triggers voice challenge", %{bypass: b, config: c} do
    stub_post(b, "/v1/one-time-token/voice/trigger", @pending)
    assert {:ok, _} = OTT.trigger_voice(c)
  end

  test "verify_pin/2 verifies PIN", %{bypass: b, config: c} do
    stub_post(b, "/v1/one-time-token/pin/verify", @passed)
    assert {:ok, s} = OTT.verify_pin(c, "1234")
    assert OTT.passed?(s)
  end

  test "passed?/1 true when all required passed" do
    assert OTT.passed?(@passed)
  end

  test "passed?/1 false when required pending" do
    refute OTT.passed?(@pending)
  end

  test "passed?/1 ignores optional challenges" do
    status = %{
      "challenges" => [
        %{"type" => "PIN", "required" => true, "passed" => true},
        %{"type" => "FACE_MAP", "required" => false, "passed" => false}
      ]
    }

    assert OTT.passed?(status)
  end
end
