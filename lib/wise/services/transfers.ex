defmodule Wise.Services.Transfers do
  @moduledoc "Wise Transfer API — payment creation, funding, and cancellation."
  alias Wise.Client

  @spec create(Wise.Config.t(), map()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, attrs), do: Client.post(config, "/v1/transfers", attrs)

  @spec get(Wise.Config.t(), Wise.Types.transfer_id()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, id), do: Client.get(config, "/v1/transfers/#{id}")

  @spec list(Wise.Config.t(), keyword()) :: {:ok, list()} | {:error, Wise.Error.t()}
  def list(config, params \\ []), do: Client.get(config, "/v1/transfers", params)

  @spec fund(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.transfer_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def fund(config, pid, tid) do
    Client.post(config, "/v3/profiles/#{pid}/transfers/#{tid}/payments", %{type: "BALANCE"})
  end

  @spec cancel(Wise.Config.t(), Wise.Types.transfer_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def cancel(config, id), do: Client.post(config, "/v1/transfers/#{id}/cancel")

  @spec delivery_estimate(Wise.Config.t(), Wise.Types.transfer_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def delivery_estimate(config, id), do: Client.get(config, "/v1/delivery-estimates/#{id}")

  @spec requirements(Wise.Config.t(), Wise.Types.transfer_id()) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def requirements(config, id), do: Client.get(config, "/v1/transfers/#{id}/requirements")

  @spec payin_deposit_details(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.transfer_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def payin_deposit_details(config, pid, tid) do
    Client.get(config, "/v1/profiles/#{pid}/transfers/#{tid}/deposit-details/bank-transfer")
  end
end
