defmodule Wise.Internal.RateLimiterTest do
  use ExUnit.Case, async: true

  alias Wise.Internal.RateLimiter

  test "allows burst requests immediately" do
    {:ok, pid} = RateLimiter.start_link(rate: 100, burst: 5)

    for _ <- 1..5 do
      assert :ok = RateLimiter.wait(pid)
    end
  end

  test "starts successfully with default options" do
    {:ok, pid} = RateLimiter.start_link(name: :"rl_default_#{:erlang.unique_integer()}")
    assert :ok = RateLimiter.wait(pid)
  end

  test "returns timeout error when drained and timeout is very short" do
    {:ok, pid} = RateLimiter.start_link(rate: 0.001, burst: 1)
    # drain the token
    RateLimiter.wait(pid)
    assert {:error, :timeout} = RateLimiter.wait(pid, 1)
  end

  test "concurrent requests all succeed with sufficient burst" do
    {:ok, pid} = RateLimiter.start_link(rate: 1000, burst: 10)
    tasks = Enum.map(1..10, fn _ -> Task.async(fn -> RateLimiter.wait(pid) end) end)
    results = Task.await_many(tasks)
    assert Enum.all?(results, &(&1 == :ok))
  end
end
