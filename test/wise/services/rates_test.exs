defmodule Wise.Services.RatesTest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Wise.Services.Rates

  @rate %{"source" => "USD", "target" => "GBP", "rate" => 0.79, "time" => "2024-01-01T00:00:00Z"}

  setup do
    {bypass, config} = setup_bypass()
    %{bypass: bypass, config: config}
  end

  test "list/2 returns rates", %{bypass: b, config: c} do
    stub_get(b, "/v1/rates", [@rate])
    assert {:ok, [r]} = Rates.list(c, source: "USD", target: "GBP")
    assert r["rate"] == 0.79
  end

  test "get/3 returns first matching rate", %{bypass: b, config: c} do
    stub_get(b, "/v1/rates", [@rate])
    assert {:ok, r} = Rates.get(c, "USD", "GBP")
    assert r["rate"] == 0.79
  end

  test "get/3 returns 404 error when no rate found", %{bypass: b, config: c} do
    stub_get(b, "/v1/rates", [])
    assert {:error, err} = Rates.get(c, "USD", "XYZ")
    assert err.status_code == 404
  end
end
