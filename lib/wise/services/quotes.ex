defmodule Wise.Services.Quotes do
  @moduledoc "Wise Quote API — rate locking and fee calculation."
  alias Wise.Client

  @doc "Creates a quote for a profile."
  @spec create(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, profile_id, attrs),
    do: Client.post(config, "/v3/profiles/#{profile_id}/quotes", attrs)

  @doc "Creates an anonymous quote (no profile required)."
  @spec create_anonymous(Wise.Config.t(), map()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def create_anonymous(config, attrs), do: Client.post(config, "/v1/quotes", attrs)

  @doc "Fetches a quote by ID."
  @spec get(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.quote_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, profile_id, quote_id),
    do: Client.get(config, "/v3/profiles/#{profile_id}/quotes/#{quote_id}")

  @doc "Updates a quote (e.g. target account or pay-in method)."
  @spec update(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.quote_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def update(config, profile_id, quote_id, attrs) do
    Client.patch(config, "/v3/profiles/#{profile_id}/quotes/#{quote_id}", attrs)
  end

  @doc "Returns account requirement fields for a quote."
  @spec account_requirements(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.quote_id()) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def account_requirements(config, pid, qid) do
    Client.get(config, "/v3/profiles/#{pid}/quotes/#{qid}/account-requirements")
  end

  @doc "Refreshes account requirements with currently filled details."
  @spec refresh_account_requirements(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.quote_id(),
          map()
        ) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def refresh_account_requirements(config, pid, qid, details) do
    Client.post(config, "/v3/profiles/#{pid}/quotes/#{qid}/account-requirements", details)
  end
end
