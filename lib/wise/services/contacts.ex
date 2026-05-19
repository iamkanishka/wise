defmodule Wise.Services.Contacts do
  @moduledoc "Wise Contact API — find profiles by Wisetag, email, or phone."
  alias Wise.Client

  @spec find(Wise.Config.t(), Wise.Types.profile_id(), map()) ::
          {:ok, map()} | {:error, Wise.Error.t()}
  def find(config, profile_id, attrs),
    do: Client.post(config, "/v2/profiles/#{profile_id}/contacts", attrs)
end
