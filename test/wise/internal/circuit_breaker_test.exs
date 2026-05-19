defmodule Wise.Internal.CircuitBreakerTest do
  use ExUnit.Case, async: true

  alias Wise.Error
  alias Wise.Internal.CircuitBreaker

  setup do
    {:ok, pid} =
      CircuitBreaker.start_link(failure_threshold: 3, success_threshold: 2, timeout_ms: 100)

    %{cb: pid}
  end

  test "starts in CLOSED state", %{cb: cb} do
    assert CircuitBreaker.current_state(cb) == :closed
  end

  test "executes fn successfully in CLOSED state", %{cb: cb} do
    assert {:ok, 42} = CircuitBreaker.execute(cb, fn -> {:ok, 42} end)
  end

  test "opens after failure_threshold consecutive failures", %{cb: cb} do
    for _ <- 1..3 do
      CircuitBreaker.execute(cb, fn -> {:error, Error.network("fail")} end)
    end

    assert CircuitBreaker.current_state(cb) == :open
  end

  test "throws circuit_open error when OPEN", %{cb: cb} do
    for _ <- 1..3 do
      CircuitBreaker.execute(cb, fn -> {:error, Error.network("fail")} end)
    end

    assert {:error, %Error{type: :circuit_open}} =
             CircuitBreaker.execute(cb, fn -> {:ok, "ok"} end)
  end

  test "transitions to HALF_OPEN after timeout", %{cb: cb} do
    for _ <- 1..3 do
      CircuitBreaker.execute(cb, fn -> {:error, Error.network("fail")} end)
    end

    assert CircuitBreaker.current_state(cb) == :open
    Process.sleep(150)
    assert CircuitBreaker.current_state(cb) == :half_open
  end

  test "returns to CLOSED after success_threshold in HALF_OPEN", %{cb: cb} do
    for _ <- 1..3 do
      CircuitBreaker.execute(cb, fn -> {:error, Error.network("fail")} end)
    end

    Process.sleep(150)
    CircuitBreaker.execute(cb, fn -> {:ok, "ok"} end)
    CircuitBreaker.execute(cb, fn -> {:ok, "ok"} end)
    assert CircuitBreaker.current_state(cb) == :closed
  end

  test "reset/1 returns to CLOSED", %{cb: cb} do
    for _ <- 1..3 do
      CircuitBreaker.execute(cb, fn -> {:error, Error.network("fail")} end)
    end

    assert :ok = CircuitBreaker.reset(cb)
    assert CircuitBreaker.current_state(cb) == :closed
    assert {:ok, "after"} = CircuitBreaker.execute(cb, fn -> {:ok, "after"} end)
  end
end
