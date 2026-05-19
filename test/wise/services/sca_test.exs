defmodule Wise.Services.SCATest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Wise.Services.SCA

  @passed_status %{
    "passed" => true,
    "challenges" => [%{"type" => "PIN", "required" => true, "passed" => true}]
  }

  @pending_status %{
    "passed" => false,
    "challenges" => [
      %{"type" => "SMS", "required" => true, "passed" => false},
      %{"type" => "PIN", "required" => false, "passed" => false}
    ]
  }

  setup do
    {bypass, config} = setup_bypass()
    %{bypass: bypass, config: config}
  end

  test "status/1 returns SCA status", %{bypass: b, config: c} do
    stub_get(b, "/v1/auth/sca/status", @passed_status)
    assert {:ok, s} = SCA.status(c)
    assert s["passed"] == true
  end

  test "verify/2 posts challenge response", %{bypass: b, config: c} do
    stub_post(b, "/v1/auth/sca/verify", @passed_status)
    assert {:ok, s} = SCA.verify(c, %{type: "PIN", pin: "123456"})
    assert s["passed"] == true
  end

  test "passed?/1 returns true when all required challenges passed" do
    assert SCA.passed?(@passed_status)
  end

  test "passed?/1 returns false when required challenge pending" do
    refute SCA.passed?(@pending_status)
  end

  test "passed?/1 ignores optional challenges" do
    mixed = %{
      "challenges" => [
        %{"type" => "PIN", "required" => true, "passed" => true},
        %{"type" => "FACE_MAP", "required" => false, "passed" => false}
      ]
    }

    assert SCA.passed?(mixed)
  end

  test "pending_challenges/1 returns only required+unpassed" do
    pending = SCA.pending_challenges(@pending_status)
    assert length(pending) == 1
    assert hd(pending)["type"] == "SMS"
  end

  test "pending_challenges/1 returns empty when all passed" do
    assert [] = SCA.pending_challenges(@passed_status)
  end
end
