defmodule Wise.Services.Cases do
  @moduledoc "Wise Partner Cases API — support case management."
  alias Wise.Client

  @spec create(Wise.Config.t(), map()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def create(config, attrs), do: Client.post(config, "/v1/cases", attrs)
  @spec get(Wise.Config.t(), Wise.Types.case_id()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def get(config, case_id), do: Client.get(config, "/v1/cases/#{case_id}")

  @spec list_comments(Wise.Config.t(), Wise.Types.case_id()) ::
          {:ok, list(map())} | {:error, Wise.Error.t()}
  def list_comments(config, case_id), do: Client.get(config, "/v1/cases/#{case_id}/comments")

  @spec add_comment(Wise.Config.t(), Wise.Types.case_id(), String.t()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def add_comment(config, case_id, body),
    do: Client.put(config, "/v1/cases/#{case_id}/comments", %{body: body})
end
