defmodule Wise.Error do
  @moduledoc """
  Structured error returned from the Wise Platform API.

  All API errors are returned as `{:error, %Wise.Error{}}` tuples.
  Network errors are returned as `{:error, %Wise.Error{type: :network}}`.

  ## Fields

    - `type` - `:api`, `:network`, `:circuit_open`, `:invalid_signature`, `:rate_limited`
    - `status_code` - HTTP status code (nil for network errors)
    - `code` - Wise machine-readable error code e.g. `"SCA_REQUIRED"`
    - `message` - Human-readable description
    - `errors` - Per-field validation errors (populated on 422)
    - `request_id` - X-Request-Id header value for Wise support

  ## Example

      case Wise.Transfers.fund(client, profile_id, transfer_id) do
        {:ok, result} -> result
        {:error, %Wise.Error{code: "SCA_REQUIRED"}} -> redirect_to_sca()
        {:error, %Wise.Error{status_code: 429}} -> handle_rate_limit()
        {:error, %Wise.Error{type: :network}} -> handle_network_error()
      end
  """

  @type error_type :: :api | :network | :circuit_open | :invalid_signature | :rate_limited

  @type field_error :: %{
          required(:field) => String.t(),
          required(:code) => String.t(),
          required(:message) => String.t()
        }

  @type t :: %__MODULE__{
          type: error_type(),
          status_code: non_neg_integer() | nil,
          code: String.t() | nil,
          message: String.t() | nil,
          errors: [field_error()],
          request_id: String.t() | nil
        }

  defexception [:type, :status_code, :code, :message, :errors, :request_id]

  @impl true
  @spec message(t()) :: String.t()
  def message(%__MODULE__{} = err) do
    parts = [
      "Wise API Error",
      err.status_code && " #{err.status_code}",
      err.code && " [#{err.code}]",
      err.message && ": #{err.message}"
    ]

    parts |> Enum.reject(&is_nil/1) |> Enum.join()
  end

  @doc "Returns true if this is a 404 Not Found error."
  @spec not_found?(t()) :: boolean()
  def not_found?(%__MODULE__{status_code: 404}), do: true
  def not_found?(_), do: false

  @doc "Returns true if SCA (Strong Customer Authentication) is required."
  @spec sca_required?(t()) :: boolean()
  def sca_required?(%__MODULE__{status_code: 403, code: "SCA_REQUIRED"}), do: true
  def sca_required?(_), do: false

  @doc "Returns true if this is a 429 rate limit error."
  @spec rate_limited?(t()) :: boolean()
  def rate_limited?(%__MODULE__{status_code: 429}), do: true
  def rate_limited?(%__MODULE__{type: :rate_limited}), do: true
  def rate_limited?(_), do: false

  @doc "Returns true if this is a 401 Unauthorized error."
  @spec unauthorized?(t()) :: boolean()
  def unauthorized?(%__MODULE__{status_code: 401}), do: true
  def unauthorized?(_), do: false

  @doc "Returns true if this is a 5xx server error."
  @spec server_error?(t()) :: boolean()
  def server_error?(%__MODULE__{status_code: code}) when is_integer(code) and code >= 500,
    do: true

  def server_error?(_), do: false

  @doc "Returns true if this is a network-level error."
  @spec network_error?(t()) :: boolean()
  def network_error?(%__MODULE__{type: :network}), do: true
  def network_error?(_), do: false

  @doc "Returns true if the circuit breaker rejected the request."
  @spec circuit_open?(t()) :: boolean()
  def circuit_open?(%__MODULE__{type: :circuit_open}), do: true
  def circuit_open?(_), do: false

  @doc "Extracts per-field validation errors from a 422 response."
  @spec field_errors(t()) :: [field_error()]
  def field_errors(%__MODULE__{errors: errors}), do: errors || []

  @doc false
  @spec from_response(map(), non_neg_integer(), String.t() | nil) :: t()
  def from_response(body, status_code, request_id \\ nil) do
    %__MODULE__{
      type: :api,
      status_code: status_code,
      code: body["code"],
      message: body["message"] || body["error"],
      errors: parse_field_errors(body["errors"]),
      request_id: request_id
    }
  end

  @doc false
  @spec network(String.t()) :: t()
  def network(reason) do
    %__MODULE__{type: :network, message: reason, errors: [], status_code: nil}
  end

  @doc false
  @spec circuit_open(non_neg_integer()) :: t()
  def circuit_open(retry_after_ms) do
    %__MODULE__{
      type: :circuit_open,
      message: "Circuit breaker is OPEN — retry after #{ceil(retry_after_ms / 1000)}s",
      errors: [],
      status_code: nil
    }
  end

  @doc false
  @spec invalid_signature() :: t()
  def invalid_signature do
    %__MODULE__{
      type: :invalid_signature,
      message: "Invalid webhook signature",
      errors: [],
      status_code: nil
    }
  end

  @spec parse_field_errors(list() | nil) :: list(field_error())
  defp parse_field_errors(nil), do: []

  defp parse_field_errors(errors) when is_list(errors) do
    Enum.map(errors, fn e ->
      %{field: e["field"] || "", code: e["code"] || "", message: e["message"] || ""}
    end)
  end

  @spec parse_field_errors(term()) :: list(field_error())
  defp parse_field_errors(_), do: []
end
