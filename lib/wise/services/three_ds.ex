defmodule Wise.Services.ThreeDS do
  @moduledoc "Wise 3D Secure challenge result notification."
  alias Wise.Client

  @spec inform_challenge_result(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, :ok} | {:error, Wise.Error.t()}
  def inform_challenge_result(config, profile_id, attrs) do
    case Client.post(config, "/v3/spend/profiles/#{profile_id}/3dsecure/challenge-result", attrs) do
      {:ok, _} -> {:ok, :ok}
      error -> error
    end
  end
end
