defmodule Wise.Services.Disputes do
  @moduledoc "Wise Disputes API — card transaction dispute management."
  alias Wise.Client

  @spec list_reasons(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def list_reasons(config, profile_id),
    do: Client.get(config, "/v3/spend/profiles/#{profile_id}/dispute-form/reasons")

  @spec dynamic_flow_entry(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          String.t(),
          String.t(),
          String.t()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def dynamic_flow_entry(config, profile_id, scheme, reason, transaction_id) do
    Client.post(
      config,
      "/v3/spend/profiles/#{profile_id}/dispute-form/flows/step/#{scheme}/#{reason}",
      %{transactionId: transaction_id}
    )
  end

  @spec submit(Wise.Config.t(), Wise.Types.profile_id(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def submit(config, profile_id, scheme, reason, body) do
    Client.post(
      config,
      "/v3/spend/profiles/#{profile_id}/dispute-form/flows/#{scheme}/#{reason}",
      body
    )
  end

  @spec upload_file(Wise.Config.t(), Wise.Types.profile_id(), String.t(), list(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def upload_file(config, profile_id, filename, content, mime_type) do
    Client.post(
      config,
      "/v4/spend/profiles/#{profile_id}/dispute-form/file",
      %{filename: filename, content: content, mimeType: mime_type}
    )
  end

  @spec list(Wise.Config.t(), Wise.Types.profile_id(), keyword()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def list(config, profile_id, params \\ []) do
    Client.get(config, "/v3/spend/profiles/#{profile_id}/disputes", params)
  end

  @spec get(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.dispute_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, profile_id, dispute_id) do
    Client.get(config, "/v3/spend/profiles/#{profile_id}/disputes/#{dispute_id}")
  end

  @spec withdraw(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.dispute_id()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def withdraw(config, profile_id, dispute_id) do
    Client.put(config, "/v3/spend/profiles/#{profile_id}/disputes/#{dispute_id}/status", %{
      status: "WITHDRAWN"
    })
  end
end
