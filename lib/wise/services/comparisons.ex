defmodule Wise.Services.Comparisons do
  @moduledoc "Wise Comparison API — multi-provider price comparison."
  alias Wise.Client

  @spec compare(Wise.Config.t(), keyword()) :: {:ok, list()} | {:error, Wise.Error.t()}
  def compare(config, params), do: Client.get(config, "/v4/comparisons", params)
end
