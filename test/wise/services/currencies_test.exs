defmodule Wise.Services.CurrenciesTest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Wise.Error
  alias Wise.Services.Currencies

  setup do
    {bypass, config} = setup_bypass()
    %{bypass: bypass, config: config}
  end

  test "list/1 returns currencies", %{bypass: b, config: c} do
    stub_get(b, "/v1/currencies", [%{"code" => "USD"}, %{"code" => "GBP"}])
    assert {:ok, [c1, c2]} = Currencies.list(c)
    assert c1["code"] == "USD"
    assert c2["code"] == "GBP"
  end

  test "returns error on 500", %{bypass: b, config: c} do
    stub_error(b, "GET", "/v1/currencies", 500, %{message: "Internal error"})
    assert {:error, err} = Currencies.list(c)
    assert Error.server_error?(err)
  end
end
