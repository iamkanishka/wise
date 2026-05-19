defmodule Wise.Test.BypassHelpers do
  alias Plug.Conn
  alias Wise.Config

  @moduledoc "Helpers for HTTP mocking via Bypass in tests."

  @doc """
  Creates a Bypass server and a Wise.Config pointed at it.
  Returns {bypass, config}.
  """
  def setup_bypass(opts \\ []) do
    bypass = Bypass.open()

    config =
      Config.new!(
        Keyword.merge(
          [
            personal_token: "test-token",
            base_url: "http://localhost:#{bypass.port}",
            max_retries: 0
          ],
          opts
        )
      )

    {bypass, config}
  end

  @doc "Stubs a GET endpoint returning JSON."
  def stub_get(bypass, path, body, status \\ 200) do
    Bypass.stub(bypass, "GET", path, fn conn ->
      conn
      |> Conn.put_resp_header("content-type", "application/json")
      |> Conn.send_resp(status, Jason.encode!(body))
    end)
  end

  @doc "Stubs a POST endpoint returning JSON."
  def stub_post(bypass, path, body, status \\ 200) do
    Bypass.stub(bypass, "POST", path, fn conn ->
      conn
      |> Conn.put_resp_header("content-type", "application/json")
      |> Conn.send_resp(status, Jason.encode!(body))
    end)
  end

  @doc "Stubs a PUT endpoint returning JSON."
  def stub_put(bypass, path, body, status \\ 200) do
    Bypass.stub(bypass, "PUT", path, fn conn ->
      conn
      |> Conn.put_resp_header("content-type", "application/json")
      |> Conn.send_resp(status, Jason.encode!(body))
    end)
  end

  @doc "Stubs a PATCH endpoint returning JSON."
  def stub_patch(bypass, path, body, status \\ 200) do
    Bypass.stub(bypass, "PATCH", path, fn conn ->
      conn
      |> Conn.put_resp_header("content-type", "application/json")
      |> Conn.send_resp(status, Jason.encode!(body))
    end)
  end

  @doc "Stubs a DELETE endpoint returning 204."
  def stub_delete(bypass, path, status \\ 204) do
    Bypass.stub(bypass, "DELETE", path, fn conn ->
      Conn.send_resp(conn, status, "")
    end)
  end

  @doc "Stubs an error response."
  def stub_error(bypass, method, path, status, body \\ %{}) do
    Bypass.stub(bypass, method, path, fn conn ->
      conn
      |> Conn.put_resp_header("content-type", "application/json")
      |> Conn.send_resp(status, Jason.encode!(body))
    end)
  end
end
