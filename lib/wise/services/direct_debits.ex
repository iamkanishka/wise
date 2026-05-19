defmodule Wise.Services.DirectDebits do
  @moduledoc "Wise Direct Debit Account API."
  alias Wise.Client

  @spec create(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, pid, attrs),
    do: Client.post(config, "/v1/profiles/#{pid}/direct-debit-accounts", attrs)

  @spec list(Wise.Config.t(), Wise.Types.profile_id()) :: {:ok, list()} | {:error, Wise.Error.t()}
  def list(config, pid), do: Client.get(config, "/v1/profiles/#{pid}/direct-debit-accounts")
end
