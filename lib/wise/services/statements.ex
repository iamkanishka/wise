defmodule Wise.Services.Statements do
  @moduledoc "Wise Balance Statement API — JSON, CSV, PDF, XLSX, MT940 downloads."
  alias Wise.Client

  @spec get_json(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.balance_id(), keyword()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_json(config, pid, bid, params \\ []) do
    Client.get(config, "/v1/profiles/#{pid}/balance-statements/#{bid}/statement.json", params)
  end

  @spec get_raw(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.balance_id(),
          String.t(),
          keyword()
        ) ::
          {:ok, binary()} | {:error, Wise.Error.t()}
  def get_raw(config, pid, bid, format, params \\ []) do
    Client.get_raw(
      config,
      "/v1/profiles/#{pid}/balance-statements/#{bid}/statement.#{format}",
      params
    )
  end
end
