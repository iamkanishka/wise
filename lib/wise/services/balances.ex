defmodule Wise.Services.Balances do
  @moduledoc "Wise Balance API — multi-currency balance management."
  alias Wise.Client

  @spec create(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, pid, attrs), do: Client.post(config, "/v4/profiles/#{pid}/balances", attrs)

  @spec list(Wise.Config.t(), Wise.Types.profile_id(), keyword()) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def list(config, pid, types \\ []) do
    t = if types == [], do: "STANDARD,SAVINGS", else: Enum.join(types, ",")
    Client.get(config, "/v4/profiles/#{pid}/balances", types: t)
  end

  @spec get(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.balance_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, pid, bid), do: Client.get(config, "/v4/profiles/#{pid}/balances/#{bid}")

  @spec close(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.balance_id()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def close(config, pid, bid), do: Client.delete(config, "/v4/profiles/#{pid}/balances/#{bid}")

  @spec move_money(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def move_money(config, pid, attrs),
    do: Client.post(config, "/v2/profiles/#{pid}/balance-movements", attrs)

  @spec get_total_funds(Wise.Config.t(), Wise.Types.profile_id(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get_total_funds(config, pid, currency),
    do: Client.get(config, "/v1/profiles/#{pid}/total-funds/#{currency}")

  @spec get_deposit_limits(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def get_deposit_limits(config, pid),
    do: Client.get(config, "/v1/profiles/#{pid}/balance-capacity")

  @spec set_excess_money_account(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.recipient_id()
        ) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def set_excess_money_account(config, pid, rid) do
    case Client.post(config, "/v1/profiles/#{pid}/excess-money-account", %{recipientId: rid}) do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end
end
