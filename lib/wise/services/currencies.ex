defmodule Wise.Services.Currencies do
  @moduledoc "Wise Currencies API — list supported currencies."
  alias Wise.Client

  @spec list(Wise.Config.t()) :: {:ok, list()} | {:error, Wise.Error.t()}
  def list(config), do: Client.get(config, "/v1/currencies")
end
