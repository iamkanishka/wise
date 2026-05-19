defmodule Wise.ConfigTest do
  use ExUnit.Case, async: true

  alias Wise.Config

  describe "new/1" do
    test "creates config with personal token (sandbox)" do
      assert {:ok, cfg} = Config.new(personal_token: "tok", sandbox: true)
      assert cfg.auth_mode == :personal_token
      assert cfg.personal_token == "tok"
      assert cfg.base_url == "https://api.wise-sandbox.com"
    end

    test "creates config with personal token (production)" do
      assert {:ok, cfg} = Config.new(personal_token: "tok")
      assert cfg.base_url == "https://api.wise.com"
    end

    test "accepts custom base_url" do
      assert {:ok, cfg} = Config.new(personal_token: "tok", base_url: "http://localhost:4000/")
      assert cfg.base_url == "http://localhost:4000"
    end

    test "strips trailing slash from base_url" do
      assert {:ok, cfg} = Config.new(personal_token: "tok", base_url: "https://custom.api.com/")
      assert cfg.base_url == "https://custom.api.com"
    end

    test "detects client_credentials auth mode" do
      assert {:ok, cfg} = Config.new(client_id: "id", client_secret: "sec")
      assert cfg.auth_mode == :client_credentials
    end

    test "detects user_token auth mode" do
      assert {:ok, cfg} = Config.new(access_token: "tok")
      assert cfg.auth_mode == :user_token
    end

    test "returns error when personal_token missing" do
      assert {:error, _msg} = Config.new([])
    end

    test "sets default timeout and retry values" do
      assert {:ok, cfg} = Config.new(personal_token: "tok")
      assert cfg.timeout == 30_000
      assert cfg.max_retries == 3
    end
  end

  describe "new!/1" do
    test "returns config on success" do
      cfg = Config.new!(personal_token: "tok", sandbox: true)
      assert cfg.auth_mode == :personal_token
    end

    test "raises on invalid config" do
      assert_raise ArgumentError, fn -> Config.new!([]) end
    end
  end

  describe "current_token/1" do
    test "returns personal token immediately" do
      cfg = Config.new!(personal_token: "my-token")
      assert {:ok, "my-token"} = Config.current_token(cfg)
    end

    test "returns user token when not expired" do
      cfg =
        Config.new!(
          access_token: "user-tok",
          token_expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
        )

      assert {:ok, "user-tok"} = Config.current_token(cfg)
    end
  end
end
