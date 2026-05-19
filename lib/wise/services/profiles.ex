defmodule Wise.Services.Profiles do
  @moduledoc "Wise Profile API — personal and business profile management."
  alias Wise.Client

  @doc "Lists all profiles for the authenticated user."
  @spec list(Wise.Config.t()) :: {:ok, list(map())} | {:error, Wise.Error.t()}
  def list(config), do: Client.get(config, "/v1/profiles")

  @doc "Fetches a profile by ID."
  @spec get(Wise.Config.t(), Wise.Types.profile_id()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, profile_id), do: Client.get(config, "/v1/profiles/#{profile_id}")

  @doc "Creates a personal profile."
  @spec create_personal(Wise.Config.t(), map()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def create_personal(config, attrs),
    do: Client.post(config, "/v1/profiles", %{type: "personal", details: attrs})

  @doc "Creates a business profile."
  @spec create_business(Wise.Config.t(), map()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def create_business(config, attrs),
    do: Client.post(config, "/v1/profiles", %{type: "business", details: attrs})

  @doc "Updates a personal profile."
  @spec update_personal(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def update_personal(config, id, attrs) do
    Client.put(config, "/v1/profiles/#{id}", %{type: "personal", details: attrs})
  end

  @doc "Updates a business profile."
  @spec update_business(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def update_business(config, id, attrs) do
    Client.put(config, "/v1/profiles/#{id}/business", %{type: "business", details: attrs})
  end
end
