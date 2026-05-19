defmodule Wise.Internal.RateLimiter do
  @moduledoc """
  Token-bucket rate limiter backed by a GenServer.

  Provides sustained throughput control for outbound API requests.
  The default bucket allows 10 requests per second with a burst of 20.

  ## Usage

      {:ok, _pid} = Wise.Internal.RateLimiter.start_link(rate: 10, burst: 20)
      :ok = Wise.Internal.RateLimiter.wait(pid)
  """

  use GenServer

  require Logger

  @default_rate 10
  @default_burst 20

  @typedoc "Rate limiter state"
  @type state :: %{
          tokens: float(),
          max_tokens: float(),
          refill_rate: float(),
          last_refill: integer()
        }

  @doc """
  Starts a rate limiter process.

  ## Options
    - `:rate` - sustained requests per second (default: #{@default_rate})
    - `:burst` - maximum burst capacity (default: #{@default_burst})
    - `:name` - GenServer registration name
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Blocks until a token is available. Returns `:ok` or `{:error, :timeout}`."
  @spec wait(GenServer.server(), timeout()) :: :ok | {:error, :timeout}
  def wait(server \\ __MODULE__, timeout \\ 5_000) do
    deadline = System.monotonic_time(:millisecond) + timeout

    do_wait(server, deadline)
  end

  @spec do_wait(GenServer.server(), integer()) :: :ok | {:error, :timeout}
  defp do_wait(server, deadline) do
    case GenServer.call(server, :acquire, :infinity) do
      :ok ->
        :ok

      {:wait, wait_ms} ->
        remaining = deadline - System.monotonic_time(:millisecond)

        if remaining <= 0 do
          {:error, :timeout}
        else
          Process.sleep(min(wait_ms, remaining))
          do_wait(server, deadline)
        end
    end
  end

  # --- GenServer callbacks ---

  @impl true
  @spec init(keyword()) :: {:ok, state()}
  def init(opts) do
    rate = Keyword.get(opts, :rate, @default_rate)
    burst = Keyword.get(opts, :burst, @default_burst)

    state = %{
      tokens: burst * 1.0,
      max_tokens: burst * 1.0,
      refill_rate: rate / 1000.0,
      last_refill: System.monotonic_time(:millisecond)
    }

    {:ok, state}
  end

  @impl true
  @spec handle_call(:acquire, GenServer.from(), state()) ::
          {:reply, :ok | {:wait, non_neg_integer()}, state()}
  def handle_call(:acquire, _from, state) do
    state = refill(state)

    if state.tokens >= 1.0 do
      {:reply, :ok, %{state | tokens: state.tokens - 1.0}}
    else
      wait_ms = ceil((1.0 - state.tokens) / state.refill_rate)
      {:reply, {:wait, wait_ms}, state}
    end
  end

  @spec refill(state()) :: state()
  defp refill(%{last_refill: last, refill_rate: rate, max_tokens: max, tokens: tokens} = state) do
    now = System.monotonic_time(:millisecond)
    elapsed = now - last
    new_tokens = min(max, tokens + elapsed * rate)
    %{state | tokens: new_tokens, last_refill: now}
  end
end
