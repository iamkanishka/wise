defmodule Wise.Services.TransfersTest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Wise.Services.Transfers

  @transfer %{
    "id" => 9001,
    "status" => "draft",
    "sourceCurrency" => "USD",
    "targetCurrency" => "GBP"
  }

  setup do
    {bypass, config} = setup_bypass()
    %{bypass: bypass, config: config}
  end

  test "create/2 posts to /v1/transfers", %{bypass: b, config: c} do
    stub_post(b, "/v1/transfers", @transfer, 201)

    assert {:ok, t} =
             Transfers.create(c, %{targetAccount: 55, quoteUuid: "q", customerTransactionId: "k"})

    assert t["id"] == 9001
    assert t["status"] == "draft"
  end

  test "get/2 returns a transfer", %{bypass: b, config: c} do
    stub_get(b, "/v1/transfers/9001", @transfer)
    assert {:ok, t} = Transfers.get(c, 9001)
    assert t["id"] == 9001
  end

  test "list/2 returns transfers", %{bypass: b, config: c} do
    stub_get(b, "/v1/transfers", [@transfer])
    assert {:ok, [t]} = Transfers.list(c)
    assert t["status"] == "draft"
  end

  test "fund/3 posts to /v3/profiles/:pid/transfers/:tid/payments", %{bypass: b, config: c} do
    stub_post(b, "/v3/profiles/1/transfers/9001/payments", %{"status" => "COMPLETED"})
    assert {:ok, r} = Transfers.fund(c, 1, 9001)
    assert r["status"] == "COMPLETED"
  end

  test "cancel/2 posts to /v1/transfers/:id/cancel", %{bypass: b, config: c} do
    stub_post(b, "/v1/transfers/9001/cancel", Map.put(@transfer, "status", "canceled"))
    assert {:ok, t} = Transfers.cancel(c, 9001)
    assert t["status"] == "canceled"
  end

  test "delivery_estimate/2 returns estimate", %{bypass: b, config: c} do
    stub_get(b, "/v1/delivery-estimates/9001", %{
      "estimatedDeliveryDate" => "2024-01-02T12:00:00Z",
      "guaranteed" => true
    })

    assert {:ok, est} = Transfers.delivery_estimate(c, 9001)
    assert est["guaranteed"] == true
  end
end
