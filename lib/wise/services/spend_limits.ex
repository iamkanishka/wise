defmodule Wise.Services.SpendLimits do
  @moduledoc "Wise Spend Limits API."
  alias Wise.Client

  @spec get_profile_limits(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_profile_limits(config, profile_id),
    do: Client.get(config, "/v1/spend/profiles/#{profile_id}/limits")

  @spec update_profile_limits(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def update_profile_limits(config, profile_id, limits) do
    Client.put(config, "/v1/spend/profiles/#{profile_id}/limits", limits)
  end

  @spec get_card_limits(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_token()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_card_limits(config, profile_id, token) do
    Client.get(config, "/v1/spend/profiles/#{profile_id}/cards/#{token}/limits")
  end

  @spec update_card_limits(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.card_token(),
          map()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def update_card_limits(config, profile_id, token, limits) do
    Client.put(config, "/v1/spend/profiles/#{profile_id}/cards/#{token}/limits", limits)
  end
end
