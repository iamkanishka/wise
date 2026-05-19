defmodule Wise.Services.WebhooksTest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Wise.Error
  alias Wise.Services.Webhooks

  @sub %{
    "id" => "sub-001",
    "name" => "test-hook",
    "triggerOn" => "transfers#state-change",
    "delivery" => %{"version" => "2.0.0", "url" => "https://example.com/hook"},
    "scope" => %{"domain" => "profile", "id" => "1"},
    "createdOn" => "2024-01-01T00:00:00Z"
  }

  setup do
    {bypass, config} = setup_bypass()
    %{bypass: bypass, config: config}
  end

  test "create/2 posts subscription", %{bypass: b, config: c} do
    stub_post(b, "/v3/profiles/1/subscriptions", @sub, 201)

    assert {:ok, s} =
             Webhooks.create(c, %{
               name: "test-hook",
               trigger_on: "transfers#state-change",
               url: "https://example.com/hook",
               profile_id: 1
             })

    assert s["id"] == "sub-001"
  end

  test "list/2 returns subscriptions", %{bypass: b, config: c} do
    stub_get(b, "/v3/profiles/1/subscriptions", [@sub])
    assert {:ok, [s]} = Webhooks.list(c, 1)
    assert s["triggerOn"] == "transfers#state-change"
  end

  test "get/3 returns a subscription", %{bypass: b, config: c} do
    stub_get(b, "/v3/profiles/1/subscriptions/sub-001", @sub)
    assert {:ok, s} = Webhooks.get(c, 1, "sub-001")
    assert s["id"] == "sub-001"
  end

  test "delete/3 sends DELETE", %{bypass: b, config: c} do
    stub_delete(b, "/v3/profiles/1/subscriptions/sub-001")
    assert {:ok, :ok} = Webhooks.delete(c, 1, "sub-001")
  end

  # ── Signature verification ────────────────────────────────────────────────

  @secret "my-webhook-secret"
  @body ~s({"eventType":"transfers#state-change","data":{}})

  defp compute_sig(body, secret) do
    :crypto.mac(:hmac, :sha256, secret, body)
    |> Base.encode16(case: :lower)
  end

  test "verify_signature/3 succeeds for valid HMAC" do
    sig = compute_sig(@body, @secret)
    assert :ok = Webhooks.verify_signature(@body, sig, @secret)
  end

  test "verify_signature/3 accepts sha256= prefix" do
    sig = "sha256=" <> compute_sig(@body, @secret)
    assert :ok = Webhooks.verify_signature(@body, sig, @secret)
  end

  test "verify_signature/3 rejects wrong signature" do
    assert {:error, %Error{type: :invalid_signature}} =
             Webhooks.verify_signature(@body, "sha256=badhex", @secret)
  end

  test "verify_signature/3 rejects empty header" do
    assert {:error, %Error{type: :invalid_signature}} =
             Webhooks.verify_signature(@body, "", @secret)
  end

  test "verify_signature/3 rejects mismatched secret" do
    sig = compute_sig(@body, "other-secret")

    assert {:error, %Error{type: :invalid_signature}} =
             Webhooks.verify_signature(@body, sig, @secret)
  end

  test "parse_event/1 decodes JSON" do
    payload =
      Jason.encode!(%{
        eventType: "transfers#state-change",
        data: %{},
        subscriptionId: "s",
        schemaVersion: "2.0.0",
        sentAt: "2024-01-01"
      })

    assert {:ok, event} = Webhooks.parse_event(payload)
    assert event["eventType"] == "transfers#state-change"
  end

  test "verify_and_parse/3 returns event on valid signature" do
    sig = "sha256=" <> compute_sig(@body, @secret)
    assert {:ok, event} = Webhooks.verify_and_parse(@body, sig, @secret)
    assert event["eventType"] == "transfers#state-change"
  end

  test "verify_and_parse/3 rejects invalid signature" do
    assert {:error, %Error{type: :invalid_signature}} =
             Webhooks.verify_and_parse(@body, "sha256=bad", @secret)
  end
end
