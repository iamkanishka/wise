defmodule Wise.Services.OAuth do
  @moduledoc "Wise OAuth 2.0 token exchange and refresh."
  alias Wise.Error

  @doc "Generates the OAuth authorization URL."
  @spec authorization_url(Wise.Config.t(), String.t(), String.t(), keyword()) :: String.t()
  def authorization_url(config, client_id, redirect_uri, opts \\ []) do
    params =
      URI.encode_query(
        [
          client_id: client_id,
          redirect_uri: redirect_uri,
          response_type: "code"
        ] ++ Keyword.take(opts, [:state, :scope])
      )

    "#{config.base_url}/oauth/authorize?#{params}"
  end

  @doc "Exchanges an authorization code for tokens."
  @spec exchange_code(Wise.Config.t(), String.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def exchange_code(config, client_id, client_secret, code, redirect_uri) do
    post_token(config, client_id, client_secret, %{
      grant_type: "authorization_code",
      code: code,
      redirect_uri: redirect_uri
    })
  end

  @doc "Exchanges a registration code for tokens."
  @spec exchange_registration_code(Wise.Config.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def exchange_registration_code(config, client_id, client_secret, reg_code) do
    post_token(config, client_id, client_secret, %{
      grant_type: "registration_code",
      registration_code: reg_code
    })
  end

  @doc "Refreshes an access token."
  @spec refresh_token(Wise.Config.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def refresh_token(config, client_id, client_secret, refresh_token) do
    post_token(config, client_id, client_secret, %{
      grant_type: "refresh_token",
      refresh_token: refresh_token
    })
  end

  @spec post_token(Wise.Config.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  defp post_token(config, client_id, client_secret, params) do
    creds = Base.encode64("#{client_id}:#{client_secret}")

    headers = [
      {"Authorization", "Basic #{creds}"},
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"User-Agent", config.user_agent}
    ]

    body = URI.encode_query(params)

    case HTTPoison.post("#{config.base_url}/oauth/token", body, headers) do
      {:ok, %{status_code: code, body: raw}} when code in 200..299 ->
        {:ok, Jason.decode!(raw)}

      {:ok, %{status_code: code, body: raw}} ->
        {:error, Error.from_response(Jason.decode!(raw), code)}

      {:error, %HTTPoison.Error{reason: r}} ->
        {:error, Error.network(inspect(r))}
    end
  end
end
