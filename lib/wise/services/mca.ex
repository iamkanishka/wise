defmodule Wise.Services.MCA do
  @moduledoc "Wise Multi Currency Account API."
  alias Wise.Client

  @spec get(Wise.Config.t(), Wise.Types.profile_id()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, profile_id),
    do: Client.get(config, "/v4/profiles/#{profile_id}/multi-currency-account")

  @spec check_eligibility(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def check_eligibility(config), do: Client.get(config, "/v4/multi-currency-account/eligibility")

  @spec available_currencies(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def available_currencies(config, profile_id) do
    Client.get(
      config,
      "/v2/borderless-accounts-configuration/profiles/#{profile_id}/available-currencies"
    )
  end

  @spec pay_in_currencies(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def pay_in_currencies(config, profile_id) do
    Client.get(
      config,
      "/v2/borderless-accounts-configuration/profiles/#{profile_id}/payin-currencies"
    )
  end
end
