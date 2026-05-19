defmodule Wise.Services.Activities do
  @moduledoc "Wise Activity API — profile event log."
  alias Wise.Client

  @spec list(Wise.Config.t(), Wise.Types.profile_id(), keyword()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def list(config, pid, params \\ []),
    do: Client.get(config, "/v1/profiles/#{pid}/activities", params)
end
