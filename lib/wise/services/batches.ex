defmodule Wise.Services.Batches do
  @moduledoc "Wise Batch Group API — batch payments up to 1,000 transfers."
  alias Wise.Client

  @spec create(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, pid, attrs),
    do: Client.post(config, "/v3/profiles/#{pid}/batch-groups", attrs)

  @spec get(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.batch_group_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, pid, id), do: Client.get(config, "/v3/profiles/#{pid}/batch-groups/#{id}")

  @spec complete(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.batch_group_id(),
          pos_integer()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def complete(config, pid, id, version) do
    Client.patch(config, "/v3/profiles/#{pid}/batch-groups/#{id}", %{
      status: "COMPLETED",
      version: version
    })
  end

  @spec cancel(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.batch_group_id(),
          pos_integer()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def cancel(config, pid, id, version) do
    Client.patch(config, "/v3/profiles/#{pid}/batch-groups/#{id}", %{
      status: "CANCELED",
      version: version
    })
  end

  @spec add_transfer(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.batch_group_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def add_transfer(config, pid, id, attrs) do
    Client.post(config, "/v3/profiles/#{pid}/batch-groups/#{id}/transfers", attrs)
  end

  @spec fund(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.batch_group_id()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def fund(config, pid, id) do
    case Client.post(config, "/v3/profiles/#{pid}/batch-payments/#{id}/payments", %{
           type: "BALANCE"
         }) do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end

  @spec fund_via_direct_debit(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.batch_group_id(),
          String.t()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def fund_via_direct_debit(config, pid, id, dd_id) do
    Client.post(config, "/v1/profiles/#{pid}/batch-groups/#{id}/payment-initiations", %{
      directDebitAccountId: dd_id
    })
  end

  @spec get_payment_initiation(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.batch_group_id(),
          String.t()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_payment_initiation(config, pid, bid, pi_id) do
    Client.get(config, "/v1/profiles/#{pid}/batch-groups/#{bid}/payment-initiations/#{pi_id}")
  end

  @spec send_settlement_journal(Wise.Config.t(), map()) :: {:ok, :ok} | {:error, Wise.Error.t()}
  def send_settlement_journal(config, journal) do
    case Client.post(config, "/v1/settlements", journal) do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end
end
