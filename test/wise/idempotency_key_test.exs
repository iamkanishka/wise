defmodule Wise.IdempotencyKeyTest do
  use ExUnit.Case, async: true

  alias Wise.IdempotencyKey

  test "new/0 returns a 32-char lowercase hex string" do
    key = IdempotencyKey.new()
    assert byte_size(key) == 32
    assert String.match?(key, ~r/^[0-9a-f]{32}$/)
  end

  test "generates unique keys" do
    keys = Enum.map(1..1000, fn _ -> IdempotencyKey.new() end)
    assert length(Enum.uniq(keys)) == 1000
  end
end
