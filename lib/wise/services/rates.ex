defmodule Wise.Services.Rates do
  @moduledoc "Wise Exchange Rate API."
  alias Wise.Client

  @spec list(Wise.Config.t(), keyword()) :: {:ok, list()} | {:error, Wise.Error.t()}
  def list(config, params \\ []), do: Client.get(config, "/v1/rates", params)

  @spec get(Wise.Config.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, source, target) do
    case Client.get(config, "/v1/rates", source: source, target: target) do
      {:ok, [rate | _]} ->
        {:ok, rate}

      {:ok, []} ->
        {:error, %Wise.Error{type: :api, status_code: 404, message: "Rate not found", errors: []}}

      error ->
        error
    end
  end
end
