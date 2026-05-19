defmodule Wise.Config do
  @moduledoc """
  Client configuration for the Wise Platform API.

  Build a config struct using `new/1` and pass it to every service call,
  or register it as a named config using `Wise.Application`.

  ## Required

  At least one of `:personal_token`, `:client_id`+`:client_secret`,
  or `:access_token` must be provided.

  ## Example

      config = Wise.Config.new!(
        personal_token: System.fetch_env!("WISE_API_TOKEN"),
        sandbox: true
      )

      {:ok, profiles} = Wise.Services.Profiles.list(config)
  """

  @production_url "https://api.wise.com"
  @sandbox_url "https://api.wise-sandbox.com"

  @type auth_mode :: :personal_token | :client_credentials | :user_token

  @type on_token_refresh ::
          (refresh_token :: String.t() ->
             {:ok,
              %{access_token: String.t(), refresh_token: String.t(), expires_at: DateTime.t()}}
             | {:error, term()})

  @type t :: %__MODULE__{
          base_url: String.t(),
          auth_mode: auth_mode(),
          personal_token: String.t() | nil,
          client_id: String.t() | nil,
          client_secret: String.t() | nil,
          access_token: String.t() | nil,
          refresh_token: String.t() | nil,
          token_expires_at: DateTime.t() | nil,
          on_token_refresh: on_token_refresh() | nil,
          timeout: pos_integer(),
          recv_timeout: pos_integer(),
          max_retries: non_neg_integer(),
          retry_base_delay: pos_integer(),
          retry_max_delay: pos_integer(),
          rate_limiter: GenServer.server() | nil,
          circuit_breaker: GenServer.server() | nil,
          request_hooks: [function()],
          response_hooks: [function()],
          user_agent: String.t()
        }

  defstruct [
    :base_url,
    :auth_mode,
    :personal_token,
    :client_id,
    :client_secret,
    :access_token,
    :refresh_token,
    :token_expires_at,
    :on_token_refresh,
    :rate_limiter,
    :circuit_breaker,
    timeout: 30_000,
    recv_timeout: 30_000,
    max_retries: 3,
    retry_base_delay: 500,
    retry_max_delay: 30_000,
    request_hooks: [],
    response_hooks: [],
    user_agent: "wise/1.0.0 (+https://github.com/iamkanishka/wise)"
  ]

  @doc """
  Creates a new config struct.

  Returns `{:ok, config}` or `{:error, reason}`.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) do
    sandbox = Keyword.get(opts, :sandbox, false)
    custom_url = Keyword.get(opts, :base_url)

    base_url =
      cond do
        custom_url != nil -> String.trim_trailing(custom_url, "/")
        sandbox -> @sandbox_url
        true -> @production_url
      end

    config = struct!(__MODULE__, [base_url: base_url] ++ Keyword.delete(opts, :base_url))
    config = detect_auth_mode(config)

    with :ok <- validate(config) do
      {:ok, config}
    end
  end

  @doc "Like `new/1` but raises on invalid configuration."
  @spec new!(keyword()) :: t()
  def new!(opts) do
    case new(opts) do
      {:ok, config} -> config
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @spec detect_auth_mode(t()) :: t()
  defp detect_auth_mode(%{personal_token: tok} = cfg) when is_binary(tok) and tok != "" do
    %{cfg | auth_mode: :personal_token}
  end

  defp detect_auth_mode(%{client_id: id, client_secret: sec} = cfg)
       when is_binary(id) and is_binary(sec) do
    %{cfg | auth_mode: :client_credentials}
  end

  defp detect_auth_mode(%{access_token: tok} = cfg) when is_binary(tok) do
    %{cfg | auth_mode: :user_token}
  end

  defp detect_auth_mode(cfg), do: %{cfg | auth_mode: :personal_token}

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%{auth_mode: :personal_token, personal_token: nil}) do
    {:error, "personal_token is required when using personal_token auth mode"}
  end

  defp validate(%{auth_mode: :client_credentials, client_id: nil}) do
    {:error, "client_id and client_secret are required for client_credentials auth"}
  end

  defp validate(%{auth_mode: :user_token, access_token: nil}) do
    {:error, "access_token is required for user_token auth mode"}
  end

  defp validate(_), do: :ok

  @doc "Returns the current Bearer token, refreshing if necessary."
  @spec current_token(t()) :: {:ok, String.t()} | {:error, Wise.Error.t()}
  def current_token(%{auth_mode: :personal_token, personal_token: tok}), do: {:ok, tok}

  def current_token(%{auth_mode: :user_token} = cfg) do
    if token_valid?(cfg.token_expires_at) do
      {:ok, cfg.access_token}
    else
      case cfg.on_token_refresh do
        nil ->
          {:ok, cfg.access_token}

        refresh_fn ->
          case refresh_fn.(cfg.refresh_token) do
            {:ok, %{access_token: tok}} -> {:ok, tok}
            {:error, _} = err -> err
          end
      end
    end
  end

  @spec current_token(t()) :: {:ok, String.t()} | {:error, atom()}
  def current_token(
        %{auth_mode: :client_credentials, access_token: tok, token_expires_at: exp} = _cfg
      )
      when is_binary(tok) do
    if token_valid?(exp), do: {:ok, tok}, else: {:error, :token_expired}
  end

  def current_token(_), do: {:error, :no_token}

  @spec token_valid?(DateTime.t() | nil) :: boolean()
  defp token_valid?(nil), do: false

  defp token_valid?(expires_at) do
    case DateTime.compare(DateTime.utc_now(), expires_at) do
      :lt -> true
      _ -> false
    end
  end
end
