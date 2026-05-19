defmodule Wise.Services.KYC do
  @moduledoc "Wise Additional Customer Verification (KYC) API."
  alias Wise.Client

  @spec get_required_evidences(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def get_required_evidences(config, profile_id) do
    Client.get(config, "/v3/profiles/#{profile_id}/verification-status/required-evidences")
  end

  @spec upload_evidences(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def upload_evidences(config, profile_id, attrs) do
    Client.post(
      config,
      "/v5/profiles/#{profile_id}/additional-verification/upload-evidences",
      attrs
    )
  end

  @deprecated "Use upload_evidences/3 (v5)"
  @spec upload_evidences_v3(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def upload_evidences_v3(config, profile_id, attrs) do
    Client.post(
      config,
      "/v3/profiles/#{profile_id}/additional-verification/upload-evidences",
      attrs
    )
  end

  @spec upload_document(Wise.Config.t(), Wise.Types.profile_id(), list(map())) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def upload_document(config, profile_id, documents) do
    Client.post(config, "/v3/profiles/#{profile_id}/verification-status/upload-document", %{
      documents: documents
    })
  end

  @spec get_kyc_status(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_kyc_status(config, profile_id),
    do: Client.get(config, "/v1/profiles/#{profile_id}/kyc/status")

  @spec submit_kyc_review(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def submit_kyc_review(config, profile_id) do
    case Client.post(config, "/v1/profiles/#{profile_id}/kyc/review") do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end
end
