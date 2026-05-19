defmodule Wise.IdempotencyKey do
  @moduledoc """
  Generates cryptographically random idempotency keys.

  Use one unique key per logical operation to ensure exactly-once semantics
  when retrying failed requests.

  ## Example

      key = Wise.IdempotencyKey.new()
      # => "a3f8c1d2e9b047f1a8c3d6e2b7f04a1c"
  """

  @doc "Generates a 32-character lowercase hex idempotency key."
  @spec new() :: String.t()
  def new do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end
end
