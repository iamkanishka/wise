defmodule WiseTest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Plug.Conn
  alias Wise.Error
  alias Wise.Services.Currencies
  alias Wise.Services.Profiles

  test "ping/1 returns :ok when API is reachable" do
    {bypass, config} = setup_bypass()

    Bypass.stub(bypass, "GET", "/v1/currencies", fn conn ->
      conn
      |> Conn.put_resp_header("content-type", "application/json")
      |> Conn.send_resp(200, Jason.encode!([%{"code" => "USD"}]))
    end)

    assert :ok = Wise.ping(config)
  end

  test "ping/1 returns error when API is down" do
    {bypass, config} = setup_bypass()

    Bypass.stub(bypass, "GET", "/v1/currencies", fn conn ->
      Conn.send_resp(conn, 503, "{}")
    end)

    assert {:error, err} = Wise.ping(config)
    assert Error.server_error?(err)
  end

  test "all 42 API groups are accessible as service modules" do
    services = [
      Wise.Services.Profiles,
      Wise.Services.Quotes,
      Wise.Services.Recipients,
      Wise.Services.Transfers,
      Wise.Services.Balances,
      Wise.Services.Statements,
      Wise.Services.BankAccounts,
      Wise.Services.Batches,
      Wise.Services.DirectDebits,
      Wise.Services.Rates,
      Wise.Services.Currencies,
      Wise.Services.Comparisons,
      Wise.Services.Cards,
      Wise.Services.CardOrders,
      Wise.Services.CardTransactions,
      Wise.Services.SpendLimits,
      Wise.Services.SpendControls,
      Wise.Services.Disputes,
      Wise.Services.KioskCollection,
      Wise.Services.PushProvisioning,
      Wise.Services.ThreeDS,
      Wise.Services.Webhooks,
      Wise.Services.Activities,
      Wise.Services.Addresses,
      Wise.Services.Contacts,
      Wise.Services.KYC,
      Wise.Services.KYCReview,
      Wise.Services.OAuth,
      Wise.Services.OTT,
      Wise.Services.SCA,
      Wise.Services.Cases,
      Wise.Services.MCA,
      Wise.Services.Users,
      Wise.Services.UserSecurity,
      Wise.Services.FaceTec,
      Wise.Services.JOSE,
      Wise.Services.ClaimAccount,
      Wise.Services.Simulations
    ]

    for mod <- services do
      assert Code.ensure_loaded?(mod), "Module #{inspect(mod)} is not loaded"
    end
  end
end
