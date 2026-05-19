defmodule Wise.Application do
  @moduledoc """
  OTP Application entry point for Wise.

  Starts the connection pool and optional background processes.
  Add `:wise` to your application's `:extra_applications` or
  include it as a dependency — it starts automatically.
  """

  use Application

  require Logger

  @impl Application
  @spec start(Application.start_type(), term()) :: {:ok, pid()} | {:error, term()}
  def start(_type, _args) do
    children = [
      # HTTPoison connection pool
      :hackney_pool.child_spec(:wise_pool,
        timeout: Application.get_env(:wise, :pool_timeout, 5_000),
        max_connections: Application.get_env(:wise, :pool_size, 10)
      )
    ]

    opts = [strategy: :one_for_one, name: Wise.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
