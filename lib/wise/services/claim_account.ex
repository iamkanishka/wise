defmodule Wise.Services.ClaimAccount do
  @moduledoc "Wise Claim Account API."
  alias Wise.Client

  @spec generate_code(Wise.Config.t(), Wise.Types.user_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def generate_code(config, user_id),
    do: Client.post(config, "/v1/user/claim-account", %{userId: user_id})
end
