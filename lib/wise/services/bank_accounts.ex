defmodule Wise.Services.BankAccounts do
  @moduledoc "Wise Bank Account Details API."
  alias Wise.Client

  @spec create_order(Wise.Config.t(), Wise.Types.profile_id(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def create_order(config, pid, currency) do
    Client.post(config, "/v1/profiles/#{pid}/account-details-orders", %{currency: currency})
  end

  @spec list(Wise.Config.t(), Wise.Types.profile_id()) :: {:ok, list()} | {:error, Wise.Error.t()}
  def list(config, pid), do: Client.get(config, "/v1/profiles/#{pid}/account-details")

  @spec list_orders(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def list_orders(config, pid),
    do: Client.get(config, "/v3/profiles/#{pid}/account-details-orders")

  @spec create_multiple_bank_details(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.balance_id()
        ) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def create_multiple_bank_details(config, pid, bid) do
    Client.post(config, "/v3/profiles/#{pid}/bank-details", %{balanceId: bid})
  end

  @spec create_payment_return(Wise.Config.t(), Wise.Types.profile_id(), String.t(), String.t()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def create_payment_return(config, pid, payment_id, reason) do
    case Client.post(
           config,
           "/v1/profiles/#{pid}/account-details/payments/#{payment_id}/returns",
           %{reason: reason}
         ) do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end
end
