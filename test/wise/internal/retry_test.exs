defmodule Wise.Internal.RetryTest do
  use ExUnit.Case, async: true

  alias Wise.Error
  alias Wise.Internal.Retry

  @fast_opts %{max_retries: 3, base_delay_ms: 1, max_delay_ms: 5}

  test "returns ok immediately on success" do
    counter = :counters.new(1, [])

    result =
      Retry.with_retry(
        fn _attempt ->
          :counters.add(counter, 1, 1)
          {:ok, "done"}
        end,
        @fast_opts
      )

    assert result == {:ok, "done"}
    assert :counters.get(counter, 1) == 1
  end

  test "retries on 429 and succeeds on second attempt" do
    counter = :counters.new(1, [])

    result =
      Retry.with_retry(
        fn _attempt ->
          n = :counters.add(counter, 1, 1) && :counters.get(counter, 1)

          if n < 2,
            do: {:error, %Error{status_code: 429, type: :api, errors: []}},
            else: {:ok, "success"}
        end,
        @fast_opts
      )

    assert {:ok, "success"} = result
    assert :counters.get(counter, 1) >= 2
  end

  test "retries on 500" do
    counter = :counters.new(1, [])

    result =
      Retry.with_retry(
        fn _attempt ->
          n = :counters.add(counter, 1, 1) && :counters.get(counter, 1)

          if n < 2,
            do: {:error, %Error{status_code: 500, type: :api, errors: []}},
            else: {:ok, "ok"}
        end,
        @fast_opts
      )

    assert {:ok, "ok"} = result
  end

  test "does not retry on 400" do
    counter = :counters.new(1, [])

    result =
      Retry.with_retry(
        fn _attempt ->
          :counters.add(counter, 1, 1)
          {:error, %Error{status_code: 400, type: :api, errors: []}}
        end,
        @fast_opts
      )

    assert {:error, %Error{status_code: 400}} = result
    assert :counters.get(counter, 1) == 1
  end

  test "retries on network errors" do
    counter = :counters.new(1, [])

    result =
      Retry.with_retry(
        fn _attempt ->
          n = :counters.add(counter, 1, 1) && :counters.get(counter, 1)

          if n < 2,
            do: {:error, Error.network("timeout")},
            else: {:ok, "recovered"}
        end,
        @fast_opts
      )

    assert {:ok, "recovered"} = result
  end

  test "exhausts retries and returns last error" do
    result =
      Retry.with_retry(
        fn _attempt ->
          {:error, %Error{status_code: 500, type: :api, errors: []}}
        end,
        @fast_opts
      )

    assert {:error, %Error{status_code: 500}} = result
  end

  test "passes attempt number to function" do
    attempts = Agent.start_link(fn -> [] end) |> elem(1)

    Retry.with_retry(
      fn attempt ->
        Agent.update(attempts, fn acc -> [attempt | acc] end)
        {:error, %Error{status_code: 500, type: :api, errors: []}}
      end,
      %{max_retries: 2, base_delay_ms: 1, max_delay_ms: 5}
    )

    recorded = Agent.get(attempts, &Enum.reverse/1)
    assert recorded == [0, 1, 2]
  end
end
