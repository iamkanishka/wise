defmodule Wise.Services.KioskCollection do
  @moduledoc "Wise Kiosk Card Production API."
  alias Wise.Client

  @spec produce_card(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_token()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def produce_card(config, profile_id, token) do
    case Client.put(config, "/v3/spend/profiles/#{profile_id}/cards/#{token}/production", %{}) do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end

  @spec get_production_status(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_token()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_production_status(config, profile_id, token) do
    Client.get(config, "/v3/spend/profiles/#{profile_id}/cards/#{token}/production")
  end
end
