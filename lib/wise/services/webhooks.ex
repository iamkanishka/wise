defmodule Wise.Services.Webhooks do
  @moduledoc """
  Wise Webhook API — subscription management and signature verification.

  ## Signature Verification

      def handle_webhook(conn) do
        body = conn.body_params |> Jason.encode!()
        sig  = get_req_header(conn, "x-signature-sha256") |> List.first()

        case Wise.Services.Webhooks.verify_signature(body, sig, secret) do
          :ok    -> dispatch(body)
          :error -> conn |> put_status(401) |> halt()
        end
      end
  """

  alias Wise.{Client, Config, Error}

  @doc "Creates a webhook subscription."
  @spec create(Config.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def create(config, %{profile_id: pid} = attrs) do
    body = %{
      name: attrs[:name],
      triggerOn: attrs[:trigger_on],
      delivery: %{version: "2.0.0", url: attrs[:url]},
      scope: %{domain: "profile", id: to_string(pid)}
    }

    Client.post(config, "/v3/profiles/#{pid}/subscriptions", body)
  end

  @doc "Lists all webhook subscriptions for a profile."
  @spec list(Config.t(), Wise.Types.profile_id()) :: {:ok, list()} | {:error, Error.t()}
  def list(config, profile_id), do: Client.get(config, "/v3/profiles/#{profile_id}/subscriptions")

  @doc "Fetches a webhook subscription by ID."
  @spec get(Config.t(), Wise.Types.profile_id(), Wise.Types.webhook_subscription_id()) ::
          {:ok, map()} | {:error, Error.t()}
  def get(config, profile_id, sub_id) do
    Client.get(config, "/v3/profiles/#{profile_id}/subscriptions/#{sub_id}")
  end

  @doc "Deletes a webhook subscription."
  @spec delete(Config.t(), Wise.Types.profile_id(), Wise.Types.webhook_subscription_id()) ::
          {:ok, :ok} | {:error, Error.t()}
  def delete(config, profile_id, sub_id) do
    Client.delete(config, "/v3/profiles/#{profile_id}/subscriptions/#{sub_id}")
  end

  @doc "Triggers a test delivery for a subscription."
  @spec test(Config.t(), Wise.Types.webhook_subscription_id()) ::
          {:ok, :ok} | {:error, Error.t()}
  def test(config, sub_id) do
    case Client.get(config, "/v3/subscriptions/#{sub_id}/test") do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end

  # ---------------------------------------------------------------------------
  # Signature verification
  # ---------------------------------------------------------------------------

  @doc """
  Verifies the HMAC-SHA256 signature of a Wise webhook payload.

  Uses Erlang's `:crypto` module — no external dependencies.
  Returns `:ok` on success or `{:error, %Wise.Error{type: :invalid_signature}}`.

  The `signature_header` value may optionally be prefixed with `"sha256="`.
  """
  @spec verify_signature(binary(), String.t(), String.t()) :: :ok | {:error, Error.t()}
  def verify_signature(body, signature_header, secret)
      when is_binary(body) and is_binary(signature_header) and is_binary(secret) do
    sig = String.trim_leading(signature_header, "sha256=")

    expected =
      :crypto.mac(:hmac, :sha256, secret, body)
      |> Base.encode16(case: :lower)

    if timing_safe_equal(sig, expected) do
      :ok
    else
      {:error, Error.invalid_signature()}
    end
  end

  @spec verify_signature(term(), term(), term()) :: :ok | {:error, Wise.Error.t()}
  def verify_signature(_, _, _), do: {:error, Error.invalid_signature()}

  @doc """
  Parses a raw JSON webhook body into a map.
  Returns `{:ok, event_map}` or `{:error, reason}`.
  """
  @spec parse_event(binary()) :: {:ok, map()} | {:error, term()}
  def parse_event(body), do: Jason.decode(body)

  @doc """
  Verifies and parses a webhook payload in one call.
  Returns `{:ok, event_map}` or `{:error, Error.t()}`.
  """
  @spec verify_and_parse(binary(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Error.t() | term()}
  def verify_and_parse(body, signature_header, secret) do
    with :ok <- verify_signature(body, signature_header, secret) do
      Jason.decode(body)
    end
  end

  # Constant-time comparison to prevent timing attacks
  @spec timing_safe_equal(String.t(), String.t()) :: boolean()
  defp timing_safe_equal(a, b) when byte_size(a) != byte_size(b), do: false

  defp timing_safe_equal(a, b) do
    :crypto.hash_equals(a, b)
  rescue
    # :crypto.hash_equals available in OTP 25+; fall back for older versions
    _ ->
      a_bytes = :binary.bin_to_list(a)
      b_bytes = :binary.bin_to_list(b)

      Enum.zip(a_bytes, b_bytes)
      |> Enum.reduce(0, fn {x, y}, acc -> :erlang.bor(acc, :erlang.bxor(x, y)) end)
      |> Kernel.==(0)
  end
end
