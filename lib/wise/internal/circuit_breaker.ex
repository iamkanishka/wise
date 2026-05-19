defmodule Wise.Internal.CircuitBreaker do
  @moduledoc """
  Circuit breaker implementing the CLOSED → OPEN → HALF_OPEN state machine.

  Protects against cascading failures by rejecting requests when too many
  consecutive failures are detected.

  ## States

  - **CLOSED** — Normal operation. All requests pass through.
  - **OPEN** — Failure threshold exceeded. Requests are rejected immediately.
  - **HALF_OPEN** — After the timeout, one probe request is allowed through.

  ## Usage

      {:ok, cb} = Wise.Internal.CircuitBreaker.start_link(failure_threshold: 5)

      case Wise.Internal.CircuitBreaker.execute(cb, fn -> make_request() end) do
        {:ok, result} -> result
        {:error, %Wise.Error{type: :circuit_open}} -> handle_open()
        {:error, err} -> handle_error(err)
      end
  """

  use GenServer

  alias Wise.Error

  @type state_name :: :closed | :open | :half_open

  @type state :: %{
          state: state_name(),
          consecutive_fails: non_neg_integer(),
          consecutive_ok: non_neg_integer(),
          opened_at: integer() | nil,
          failure_threshold: pos_integer(),
          success_threshold: pos_integer(),
          timeout_ms: pos_integer()
        }

  @doc """
  Starts a circuit breaker process.

  ## Options
    - `:failure_threshold` - failures before opening (default: 5)
    - `:success_threshold` - successes in HALF_OPEN before closing (default: 2)
    - `:timeout_ms` - ms to stay OPEN before going HALF_OPEN (default: 30_000)
    - `:name` - GenServer registration name
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Returns the current circuit state: `:closed`, `:open`, or `:half_open`."
  @spec current_state(GenServer.server()) :: state_name()
  def current_state(server \\ __MODULE__) do
    GenServer.call(server, :current_state)
  end

  @doc "Resets the circuit breaker to CLOSED state."
  @spec reset(GenServer.server()) :: :ok
  def reset(server \\ __MODULE__) do
    GenServer.call(server, :reset)
  end

  @doc """
  Executes `fun` through the circuit breaker.

  Returns `{:ok, result}` on success or `{:error, Wise.Error.t()}` on failure.
  If the circuit is OPEN, returns `{:error, %Wise.Error{type: :circuit_open}}` immediately.
  """
  @spec execute(GenServer.server(), (-> {:ok, any()} | {:error, any()})) ::
          {:ok, any()} | {:error, Error.t()}
  def execute(server \\ __MODULE__, fun) do
    case GenServer.call(server, :check) do
      {:ok, :proceed} ->
        result = fun.()
        GenServer.cast(server, if(match?({:ok, _}, result), do: :success, else: :failure))
        result

      {:error, _} = err ->
        err
    end
  end

  # --- GenServer callbacks ---

  @impl true
  @spec init(keyword()) :: {:ok, state()}
  def init(opts) do
    state = %{
      state: :closed,
      consecutive_fails: 0,
      consecutive_ok: 0,
      opened_at: nil,
      failure_threshold: Keyword.get(opts, :failure_threshold, 5),
      success_threshold: Keyword.get(opts, :success_threshold, 2),
      timeout_ms: Keyword.get(opts, :timeout_ms, 30_000)
    }

    {:ok, state}
  end

  @impl true
  @spec handle_call(:current_state | :check | :reset, GenServer.from(), state()) ::
          {:reply, term(), state()}
  def handle_call(:current_state, _from, state) do
    state = maybe_transition_to_half_open(state)
    {:reply, state.state, state}
  end

  @impl true
  @spec handle_call(:check, GenServer.from(), state()) ::
          {:reply, {:ok, :proceed} | {:error, Wise.Error.t()}, state()}
  def handle_call(:check, _from, state) do
    state = maybe_transition_to_half_open(state)

    case state.state do
      :open ->
        retry_after =
          state.timeout_ms - (System.monotonic_time(:millisecond) - (state.opened_at || 0))

        {:reply, {:error, Error.circuit_open(max(0, retry_after))}, state}

      _ ->
        {:reply, {:ok, :proceed}, state}
    end
  end

  @impl true
  @spec handle_call(:reset, GenServer.from(), state()) :: {:reply, :ok, map()}
  def handle_call(:reset, _from, _state) do
    fresh = %{state: :closed, consecutive_fails: 0, consecutive_ok: 0, opened_at: nil}
    {:reply, :ok, fresh}
  end

  @impl true
  @spec handle_cast(:success | :failure, state()) :: {:noreply, state()}
  def handle_cast(:success, %{state: :half_open} = state) do
    state = %{state | consecutive_ok: state.consecutive_ok + 1, consecutive_fails: 0}

    state =
      if state.consecutive_ok >= state.success_threshold,
        do: %{state | state: :closed, consecutive_ok: 0, opened_at: nil},
        else: state

    {:noreply, state}
  end

  @impl true
  @spec handle_cast(:success, state()) :: {:noreply, state()}
  def handle_cast(:success, state) do
    {:noreply, %{state | consecutive_fails: 0}}
  end

  @impl true
  @spec handle_cast(:failure, state()) :: {:noreply, state()}
  def handle_cast(:failure, state) do
    state = %{state | consecutive_fails: state.consecutive_fails + 1, consecutive_ok: 0}

    state =
      if state.state == :half_open or state.consecutive_fails >= state.failure_threshold do
        %{state | state: :open, opened_at: System.monotonic_time(:millisecond)}
      else
        state
      end

    {:noreply, state}
  end

  @spec maybe_transition_to_half_open(state()) :: state()
  defp maybe_transition_to_half_open(
         %{state: :open, opened_at: opened_at, timeout_ms: timeout} = s
       )
       when not is_nil(opened_at) do
    if System.monotonic_time(:millisecond) - opened_at >= timeout do
      %{s | state: :half_open, consecutive_ok: 0}
    else
      s
    end
  end

  defp maybe_transition_to_half_open(state), do: state
end
