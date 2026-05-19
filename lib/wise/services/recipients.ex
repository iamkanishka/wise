defmodule Wise.Services.Recipients do
  @moduledoc "Wise Recipient Account API — beneficiary account management."
  alias Wise.Client

  @spec create(Wise.Config.t(), map()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, attrs), do: Client.post(config, "/v1/accounts", attrs)

  @spec get(Wise.Config.t(), Wise.Types.recipient_id()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, id), do: Client.get(config, "/v1/accounts/#{id}")

  @spec delete(Wise.Config.t(), Wise.Types.recipient_id()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def delete(config, id), do: Client.delete(config, "/v1/accounts/#{id}")

  @spec list(Wise.Config.t(), keyword()) :: {:ok, list()} | {:error, Wise.Error.t()}
  def list(config, params \\ []), do: Client.get(config, "/v1/accounts", params)

  @spec account_requirements(Wise.Config.t(), String.t(), String.t(), number()) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def account_requirements(config, source, target, amount) do
    Client.get(config, "/v1/account-requirements",
      source: source,
      target: target,
      sourceAmount: amount
    )
  end

  @spec refresh_account_requirements(Wise.Config.t(), String.t(), String.t(), number(), map()) ::
          {:ok, list()} | {:error, Wise.Error.t()}
  def refresh_account_requirements(config, source, target, amount, details) do
    Client.post(
      config,
      "/v1/account-requirements?source=#{source}&target=#{target}&sourceAmount=#{amount}",
      details
    )
  end
end
