defmodule Wise.Services.CardTransactions do
  @moduledoc "Wise Card Transaction API."
  alias Wise.Client

  @spec list(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_token(), keyword()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def list(config, profile_id, card_token, params \\ []) do
    Client.get(
      config,
      "/v4/spend/profiles/#{profile_id}/cards/#{card_token}/transactions",
      params
    )
  end

  @spec get(Wise.Config.t(), Wise.Types.profile_id(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, profile_id, transaction_id) do
    Client.get(config, "/v4/spend/profiles/#{profile_id}/cards/transactions/#{transaction_id}")
  end
end
