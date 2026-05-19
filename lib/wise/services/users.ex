defmodule Wise.Services.Users do
  @moduledoc "Wise User API."
  alias Wise.Client

  @spec create(Wise.Config.t(), map()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, attrs), do: Client.post(config, "/v1/users", attrs)
  @spec me(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def me(config), do: Client.get(config, "/v1/me")
  @spec get(Wise.Config.t(), Wise.Types.user_id()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, user_id), do: Client.get(config, "/v1/users/#{user_id}")
end
