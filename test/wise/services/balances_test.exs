defmodule Wise.Services.BalancesTest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Wise.Services.Balances

  @balance %{
    "id" => 100,
    "currency" => "GBP",
    "type" => "STANDARD",
    "amount" => %{"value" => 5000, "currency" => "GBP"}
  }

  setup do
    {bypass, config} = setup_bypass()
    %{bypass: bypass, config: config}
  end

  test "create/3 posts to /v4/profiles/:id/balances", %{bypass: b, config: c} do
    stub_post(b, "/v4/profiles/1/balances", @balance, 201)
    assert {:ok, bal} = Balances.create(c, 1, %{currency: "GBP", type: "STANDARD"})
    assert bal["currency"] == "GBP"
  end

  test "list/2 returns balances", %{bypass: b, config: c} do
    stub_get(b, "/v4/profiles/1/balances", [@balance])
    assert {:ok, [bal]} = Balances.list(c, 1)
    assert bal["id"] == 100
  end

  test "get/3 returns a balance", %{bypass: b, config: c} do
    stub_get(b, "/v4/profiles/1/balances/100", @balance)
    assert {:ok, bal} = Balances.get(c, 1, 100)
    assert bal["currency"] == "GBP"
  end

  test "close/3 sends DELETE", %{bypass: b, config: c} do
    stub_delete(b, "/v4/profiles/1/balances/100")
    assert {:ok, :ok} = Balances.close(c, 1, 100)
  end

  test "get_deposit_limits/2 returns limits", %{bypass: b, config: c} do
    stub_get(b, "/v1/profiles/1/balance-capacity", [%{"currency" => "SGD", "max" => 5000}])
    assert {:ok, [limit]} = Balances.get_deposit_limits(c, 1)
    assert limit["currency"] == "SGD"
    assert limit["max"] == 5000
  end

  test "set_excess_money_account/3 posts recipient ID", %{bypass: b, config: c} do
    stub_post(b, "/v1/profiles/1/excess-money-account", %{})
    assert {:ok, :ok} = Balances.set_excess_money_account(c, 1, 999)
  end
end
