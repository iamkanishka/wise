defmodule Wise.Services.SCA do
  @moduledoc "Wise Strong Customer Authentication (SCA) API."
  alias Wise.Client

  @spec status(Wise.Config.t()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def status(config), do: Client.get(config, "/v1/auth/sca/status")
  @spec verify(Wise.Config.t(), map()) :: {:ok, map()} | {:error, Wise.Error.t()}
  def verify(config, attrs), do: Client.post(config, "/v1/auth/sca/verify", attrs)

  @doc "Returns true if all required challenges have been passed."
  @spec passed?(map()) :: boolean()
  def passed?(%{"challenges" => challenges}) do
    Enum.all?(challenges, fn c -> !c["required"] || c["passed"] end)
  end

  @spec passed?(term()) :: boolean()
  def passed?(_), do: false

  @doc "Returns list of required+unpassed challenges."
  @spec pending_challenges(map()) :: list(map())
  def pending_challenges(%{"challenges" => challenges}) do
    Enum.filter(challenges, fn c -> c["required"] && !c["passed"] end)
  end

  @spec pending_challenges(term()) :: list(map())
  def pending_challenges(_), do: []
end
