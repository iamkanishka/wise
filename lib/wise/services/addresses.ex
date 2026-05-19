defmodule Wise.Services.Addresses do
  @moduledoc "Wise Address API — profile address management."
  alias Wise.Client

  @spec create(Wise.Config.t(), map()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, attrs), do: Client.post(config, "/v1/addresses", attrs)

  @spec list(Wise.Config.t(), Wise.Types.profile_id()) :: {:ok, list()} | {:error, Wise.Error.t()}
  def list(config, pid), do: Client.get(config, "/v1/addresses", profile: pid)

  @spec get(Wise.Config.t(), Wise.Types.address_id()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, id), do: Client.get(config, "/v1/addresses/#{id}")

  @spec requirements(Wise.Config.t(), String.t() | nil) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def requirements(config, country \\ nil) do
    params = if country, do: [country: country], else: []
    Client.get(config, "/v1/address-requirements", params)
  end

  @spec refresh_requirements(Wise.Config.t(), map()) :: {:ok, list()} | {:error, Wise.Error.t()}
  def refresh_requirements(config, details),
    do: Client.post(config, "/v1/address-requirements", details)
end
