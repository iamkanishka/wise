defmodule Wise.Services.KYCReview do
  @moduledoc "Wise KYC Review API — hosted and API-based verification workflows."
  alias Wise.Client

  @spec create(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, profile_id, attrs),
    do: Client.post(config, "/v1/profiles/#{profile_id}/kyc-reviews", attrs)

  @spec list(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def list(config, profile_id), do: Client.get(config, "/v1/profiles/#{profile_id}/kyc-reviews")

  @spec update_redirect_url(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.kyc_review_id(),
          String.t()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def update_redirect_url(config, profile_id, review_id, url) do
    Client.patch(config, "/v1/profiles/#{profile_id}/kyc-reviews/#{review_id}", %{
      redirectUrl: url
    })
  end

  @spec get_by_id(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.kyc_review_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_by_id(config, profile_id, review_id) do
    Client.get(config, "/v2/profiles/#{profile_id}/kyc-reviews/#{review_id}")
  end

  @deprecated "Use get_by_id/3 (v2)"
  @spec get_by_id_v1(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.kyc_review_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_by_id_v1(config, profile_id, review_id) do
    Client.get(config, "/v1/profiles/#{profile_id}/kyc-reviews/#{review_id}")
  end

  @spec submit_requirement(Wise.Config.t(), Wise.Types.profile_id(), String.t(), map()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def submit_requirement(config, profile_id, key, payload) do
    Client.post(config, "/v2/profiles/#{profile_id}/kyc-requirements/#{key}", payload)
  end
end
