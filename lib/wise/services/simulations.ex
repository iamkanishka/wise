defmodule Wise.Services.Simulations do
  @moduledoc "Wise Simulation API — sandbox-only state advancement."
  alias Wise.Client

  @spec advance_transfer(Wise.Config.t(), Wise.Types.transfer_id(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def advance_transfer(config, id, state) do
    Client.post(config, "/v1/simulation/transfers/#{id}/#{state}")
  end

  @spec simulate_card_production(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.card_token(),
          String.t(),
          String.t() | nil
        ) :: {:ok, :ok} | {:error, Wise.Error.t()}
  def simulate_card_production(config, pid, card_token, status, error_code \\ nil) do
    body =
      %{status: status}
      |> then(fn b -> if error_code, do: Map.put(b, :errorCode, error_code), else: b end)

    case Client.post(
           config,
           "/v3/spend/profiles/#{pid}/simulation/card-production/#{card_token}",
           body
         ) do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end

  @spec simulate_incoming_payment(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.balance_id(),
          map()
        ) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def simulate_incoming_payment(config, pid, bid, amount) do
    case Client.post(config, "/v1/simulation/balance/topup", %{
           profileId: pid,
           balanceId: bid,
           amount: amount
         }) do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end
end
