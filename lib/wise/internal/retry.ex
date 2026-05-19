defmodule Wise.Internal.Retry do
  @moduledoc """
  Exponential back-off retry with full jitter.

  Uses `:crypto.strong_rand_bytes/1` for cryptographically safe jitter.
  Retries on HTTP 429 and 5xx. Does not retry 4xx (except 429).
  """

  require Logger

  alias Wise.Error

  @type opts :: %{
          max_retries: non_neg_integer(),
          base_delay_ms: pos_integer(),
          max_delay_ms: pos_integer()
        }

  @default_opts %{
    max_retries: 3,
    base_delay_ms: 500,
    max_delay_ms: 30_000
  }

  @doc """
  Executes `fun` with retry logic.

  `fun` must return `{:ok, result}` or `{:error, Wise.Error.t()}`.
  """
  @spec with_retry((non_neg_integer() -> {:ok, any()} | {:error, Wise.Error.t()}), opts()) ::
          {:ok, any()} | {:error, Wise.Error.t()}
  def with_retry(fun, opts \\ @default_opts) do
    do_retry(fun, 0, opts)
  end

  @spec do_retry(
          (non_neg_integer() -> {:ok, any()} | {:error, Wise.Error.t()}),
          non_neg_integer(),
          map()
        ) ::
          {:ok, any()} | {:error, Wise.Error.t()}
  defp do_retry(fun, attempt, opts) do
    case fun.(attempt) do
      {:ok, _} = ok ->
        ok

      {:error, err} = error ->
        if retryable?(err) and attempt < opts.max_retries do
          delay = jittered_delay(attempt, opts)

          Logger.debug(
            "Wise retry #{attempt + 1}/#{opts.max_retries} in #{delay}ms: #{Error.message(err)}"
          )

          Process.sleep(delay)
          do_retry(fun, attempt + 1, opts)
        else
          error
        end
    end
  end

  @spec retryable?(term()) :: boolean()
  defp retryable?(%Error{status_code: 429}), do: true
  defp retryable?(%Error{status_code: code}) when is_integer(code) and code >= 500, do: true
  defp retryable?(%Error{type: :network}), do: true
  defp retryable?(_), do: false

  @spec jittered_delay(non_neg_integer(), map()) :: non_neg_integer()
  defp jittered_delay(attempt, opts) do
    exp = trunc(:math.pow(2, attempt) * opts.base_delay_ms)
    max_delay = min(exp, opts.max_delay_ms)
    # Cryptographically safe random jitter
    <<rand::32>> = :crypto.strong_rand_bytes(4)
    rem(rand, max_delay + 1)
  end
end
