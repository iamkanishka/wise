defmodule Wise.Services.FaceTec do
  @moduledoc "Wise FaceTec biometric public key API."
  alias Wise.Client

  @spec get_public_key(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get_public_key(config), do: Client.get(config, "/v1/facetec/public-key")
end
