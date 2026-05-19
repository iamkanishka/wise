defmodule Wise.Services.CardsTest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Wise.Services.Cards

  @card %{
    "cardToken" => "tok-abc",
    "status" => "ACTIVE",
    "cardType" => "VIRTUAL",
    "cardHolderName" => "Alice"
  }
  @perms %{
    "allowTransactions" => true,
    "allowCashWithdrawals" => false,
    "allowOnlineTransactions" => true,
    "allowContactless" => true,
    "allowMobileWallets" => true,
    "allowSwipeTransactions" => false,
    "allowChipTransactions" => true
  }

  setup do
    {bypass, config} = setup_bypass()
    %{bypass: bypass, config: config}
  end

  test "list/2 returns cards", %{bypass: b, config: c} do
    stub_get(b, "/v3/spend/profiles/1/cards", [@card])
    assert {:ok, [card]} = Cards.list(c, 1)
    assert card["cardToken"] == "tok-abc"
  end

  test "get/3 fetches a card", %{bypass: b, config: c} do
    stub_get(b, "/v3/spend/profiles/1/cards/tok-abc", @card)
    assert {:ok, card} = Cards.get(c, 1, "tok-abc")
    assert card["status"] == "ACTIVE"
  end

  test "update_status/4 changes to FROZEN", %{bypass: b, config: c} do
    stub_put(b, "/v3/spend/profiles/1/cards/tok-abc/status", Map.put(@card, "status", "FROZEN"))
    assert {:ok, card} = Cards.update_status(c, 1, "tok-abc", "FROZEN")
    assert card["status"] == "FROZEN"
  end

  test "get_spending_permissions/3 returns permissions", %{bypass: b, config: c} do
    stub_get(b, "/v3/spend/profiles/1/cards/tok-abc/spending-permissions", @perms)
    assert {:ok, p} = Cards.get_spending_permissions(c, 1, "tok-abc")
    assert p["allowTransactions"] == true
    assert p["allowCashWithdrawals"] == false
  end

  test "update_single_permission/5 patches v3 endpoint", %{bypass: b, config: c} do
    updated = Map.put(@perms, "allowTransactions", false)
    stub_patch(b, "/v3/spend/profiles/1/cards/tok-abc/spending-permissions", updated)
    assert {:ok, p} = Cards.update_single_permission(c, 1, "tok-abc", "allowTransactions", false)
    assert p["allowTransactions"] == false
  end

  test "update_spending_permissions/4 patches v4 endpoint", %{bypass: b, config: c} do
    stub_patch(b, "/v4/spend/profiles/1/cards/tok-abc/spending-permissions", @perms)
    assert {:ok, p} = Cards.update_spending_permissions(c, 1, "tok-abc", @perms)
    assert p["allowCashWithdrawals"] == false
  end
end
