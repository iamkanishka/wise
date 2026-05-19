defmodule Wise.Services.CardOrders do
  @moduledoc "Wise Card Order API."
  alias Wise.Client

  @spec create(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, profile_id, attrs),
    do: Client.post(config, "/v3/spend/profiles/#{profile_id}/card-orders", attrs)

  @spec list(Wise.Config.t(), Wise.Types.profile_id(), keyword()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def list(config, profile_id, params \\ []) do
    Client.get(config, "/v3/spend/profiles/#{profile_id}/card-orders", params)
  end

  @spec get(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_order_id()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, profile_id, id),
    do: Client.get(config, "/v3/spend/profiles/#{profile_id}/card-orders/#{id}")

  @spec list_programs(Wise.Config.t(), Wise.Types.profile_id()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def list_programs(config, profile_id) do
    Client.get(config, "/v3/spend/profiles/#{profile_id}/card-orders/availability")
  end

  @spec get_requirements(Wise.Config.t(), Wise.Types.profile_id(), Wise.Types.card_order_id()) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def get_requirements(config, profile_id, id) do
    Client.get(config, "/v3/spend/profiles/#{profile_id}/card-orders/#{id}/requirements")
  end

  @spec update_status(
          Wise.Config.t(),
          Wise.Types.profile_id(),
          Wise.Types.card_order_id(),
          String.t()
        ) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def update_status(config, profile_id, id, status) do
    Client.put(config, "/v3/spend/profiles/#{profile_id}/card-orders/#{id}/status", %{
      status: status
    })
  end

  @spec validate_address(Wise.Config.t(), map()) :: {:ok, :ok} | {:error, Wise.Error.t()}
  def validate_address(config, addr), do: Client.post(config, "/v3/spend/address/validate", addr)

  @spec set_preset_pin(Wise.Config.t(), Wise.Types.card_order_id(), String.t()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def set_preset_pin(config, card_order_id, encrypted_pin) do
    Client.post(
      config,
      "/twcard-data/v1/sensitive-card-data/preset-pin",
      %{cardOrderId: card_order_id, encryptedPin: encrypted_pin}
    )
  end
end
