defmodule Wise.Services.SpendControls do
  @moduledoc "Wise Spend Controls API — MCC and transaction-type restrictions."
  alias Wise.Client

  @spec get(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_token()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, profile_id, token) do
    Client.get(config, "/v1/spend/profiles/#{profile_id}/cards/#{token}/spend-controls")
  end

  @spec update(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_token(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def update(config, profile_id, token, controls) do
    Client.put(config, "/v1/spend/profiles/#{profile_id}/cards/#{token}/spend-controls", controls)
  end
end
