defmodule Wise.Services.PushProvisioning do
  @moduledoc "Wise Push Provisioning API — Apple/Google Pay wallet integration."
  alias Wise.Client

  @spec create_session(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_token(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def create_session(config, profile_id, token, attrs) do
    Client.post(config, "/v3/spend/profiles/#{profile_id}/cards/#{token}/push-provision", attrs)
  end

  @spec get_status(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_token()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_status(config, profile_id, token) do
    Client.get(config, "/v3/spend/profiles/#{profile_id}/cards/#{token}/push-provision")
  end
end
