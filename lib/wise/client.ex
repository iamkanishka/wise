defmodule Wise.Client do
  @moduledoc """
  Core HTTP client for the Wise Platform API.

  Handles authentication, JSON encoding/decoding, error parsing,
  rate limiting, circuit breaking, and retry logic.

  All service modules delegate to this client.
  """

  require Logger

  alias Wise.{Config, Error}
  alias Wise.Internal.{CircuitBreaker, RateLimiter, Retry}

  @doc """
  Performs a GET request.
  """
  @spec get(Config.t(), String.t(), keyword()) ::
          {:ok, any()} | {:error, Error.t()}
  def get(config, path, params \\ []) do
    request(config, :get, path, nil, params)
  end

  @doc """
  Performs a POST request with JSON body.
  """
  @spec post(Config.t(), String.t(), any()) ::
          {:ok, any()} | {:error, Error.t()}
  def post(config, path, body \\ nil) do
    request(config, :post, path, body, [])
  end

  @doc """
  Performs a PUT request with JSON body.
  """
  @spec put(Config.t(), String.t(), any()) ::
          {:ok, any()} | {:error, Error.t()}
  def put(config, path, body \\ nil) do
    request(config, :put, path, body, [])
  end

  @doc """
  Performs a PATCH request with JSON body.
  """
  @spec patch(Config.t(), String.t(), any()) ::
          {:ok, any()} | {:error, Error.t()}
  def patch(config, path, body \\ nil) do
    request(config, :patch, path, body, [])
  end

  @doc """
  Performs a DELETE request.
  """
  @spec delete(Config.t(), String.t()) :: {:ok, :ok} | {:error, Error.t()}
  def delete(config, path) do
    case request(config, :delete, path, nil, []) do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end

  @doc """
  Performs a GET request and returns raw binary (for statement downloads).
  """
  @spec get_raw(Config.t(), String.t(), keyword()) ::
          {:ok, binary()} | {:error, Error.t()}
  def get_raw(config, path, params \\ []) do
    with {:ok, token} <- Config.current_token(config),
         url <- build_url(config.base_url, path, params),
         headers <- base_headers(config, token),
         opts <- httpoison_opts(config) do
      case HTTPoison.get(url, headers, opts) do
        {:ok, %{status_code: code, body: body}} when code in 200..299 ->
          {:ok, body}

        {:ok, %{status_code: code, body: body, headers: resp_headers}} ->
          request_id = get_request_id(resp_headers)
          {:error, parse_error(body, code, request_id)}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, Error.network(inspect(reason))}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Core request
  # ---------------------------------------------------------------------------

  @spec request(Wise.Config.t(), atom(), String.t(), term(), keyword()) ::
          {:ok, term()} | {:error, Wise.Error.t()}
  defp request(config, method, path, body, params) do
    retry_opts = %{
      max_retries: config.max_retries,
      base_delay_ms: config.retry_base_delay,
      max_delay_ms: config.retry_max_delay
    }

    execute_fn = fn ->
      fn attempt ->
        do_request(config, method, path, body, params, attempt)
      end
    end

    case config.circuit_breaker do
      nil ->
        Retry.with_retry(execute_fn.(), retry_opts)

      cb ->
        CircuitBreaker.execute(cb, fn ->
          Retry.with_retry(execute_fn.(), retry_opts)
        end)
    end
  end

  @spec do_request(Wise.Config.t(), atom(), String.t(), term(), keyword(), non_neg_integer()) ::
          {:ok, term()} | {:error, Wise.Error.t()}
  defp do_request(config, method, path, body, params, _attempt) do
    with {:ok, token} <- Config.current_token(config) do
      url = build_url(config.base_url, path, params)
      headers = build_headers(config, token, body)
      encoded_body = encode_body(body)
      opts = httpoison_opts(config)

      headers = apply_request_hooks(config.request_hooks, headers)

      case config.rate_limiter do
        nil -> :ok
        rl -> RateLimiter.wait(rl)
      end

      start = System.monotonic_time(:millisecond)
      result = HTTPoison.request(method, url, encoded_body, headers, opts)
      latency = System.monotonic_time(:millisecond) - start

      case result do
        {:ok, %{status_code: code, body: raw_body, headers: resp_headers} = resp} ->
          apply_response_hooks(config.response_hooks, resp, latency)

          if code in 200..299 do
            {:ok, decode_body(raw_body)}
          else
            request_id = get_request_id(resp_headers)
            {:error, parse_error(raw_body, code, request_id)}
          end

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, Error.network(inspect(reason))}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  @spec build_url(String.t(), String.t(), keyword()) :: String.t()
  defp build_url(base, path, []), do: "#{base}#{path}"

  defp build_url(base, path, params) do
    query = URI.encode_query(Enum.filter(params, fn {_, v} -> v != nil end))

    if query == "" do
      "#{base}#{path}"
    else
      "#{base}#{path}?#{query}"
    end
  end

  @spec base_headers(Wise.Config.t(), String.t()) :: list({String.t(), String.t()})
  defp base_headers(config, token) do
    [
      {"Authorization", "Bearer #{token}"},
      {"User-Agent", config.user_agent},
      {"Accept", "application/json"}
    ]
  end

  @spec build_headers(Wise.Config.t(), String.t(), term()) :: list({String.t(), String.t()})
  defp build_headers(config, token, nil), do: base_headers(config, token)

  defp build_headers(config, token, _body) do
    [{"Content-Type", "application/json"} | base_headers(config, token)]
  end

  @spec encode_body(term()) :: String.t()
  defp encode_body(nil), do: ""
  defp encode_body(body), do: Jason.encode!(body)

  @spec decode_body(String.t()) :: term()
  defp decode_body(""), do: nil

  defp decode_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> body
    end
  end

  @spec parse_error(String.t(), non_neg_integer(), String.t() | nil) :: Wise.Error.t()
  defp parse_error(body, status_code, request_id) do
    parsed =
      case Jason.decode(body) do
        {:ok, map} when is_map(map) -> map
        _ -> %{}
      end

    Error.from_response(parsed, status_code, request_id)
  end

  @spec get_request_id(list()) :: String.t() | nil
  defp get_request_id(headers) do
    case List.keyfind(headers, "X-Request-Id", 0) do
      {_, v} ->
        v

      nil ->
        case List.keyfind(headers, "x-request-id", 0) do
          {_, v} -> v
          nil -> nil
        end
    end
  end

  @spec httpoison_opts(Wise.Config.t()) :: keyword()
  defp httpoison_opts(config) do
    [
      timeout: config.timeout,
      recv_timeout: config.recv_timeout,
      hackney: [pool: :wise_pool]
    ]
  end

  @spec apply_request_hooks(list(), list()) :: list()
  defp apply_request_hooks([], headers), do: headers

  defp apply_request_hooks(hooks, headers) do
    Enum.reduce(hooks, headers, fn hook, acc -> hook.(acc) end)
  end

  @spec apply_response_hooks(list(), term(), non_neg_integer()) :: :ok
  defp apply_response_hooks([], _resp, _latency), do: :ok

  defp apply_response_hooks(hooks, resp, latency) do
    Enum.each(hooks, fn hook -> hook.(resp, latency) end)
  end
end
