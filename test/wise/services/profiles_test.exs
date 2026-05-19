defmodule Wise.Services.ProfilesTest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Wise.Error
  alias Wise.Services.Profiles

  @profile %{"id" => 1, "type" => "personal"}
  @business %{"id" => 2, "type" => "business"}

  setup do
    {bypass, config} = setup_bypass()
    %{bypass: bypass, config: config}
  end

  test "list/1 returns profiles", %{bypass: b, config: c} do
    stub_get(b, "/v1/profiles", [@profile, @business])
    assert {:ok, [p1, p2]} = Profiles.list(c)
    assert p1["type"] == "personal"
    assert p2["type"] == "business"
  end

  test "get/2 returns a profile by ID", %{bypass: b, config: c} do
    stub_get(b, "/v1/profiles/1", @profile)
    assert {:ok, p} = Profiles.get(c, 1)
    assert p["id"] == 1
  end

  test "create_personal/2 posts to /v1/profiles", %{bypass: b, config: c} do
    stub_post(b, "/v1/profiles", @profile, 201)

    assert {:ok, p} =
             Profiles.create_personal(c, %{
               firstName: "Alice",
               lastName: "Smith",
               dateOfBirth: "1990-01-01"
             })

    assert p["type"] == "personal"
  end

  test "create_business/2 posts to /v1/profiles", %{bypass: b, config: c} do
    stub_post(b, "/v1/profiles", @business, 201)
    assert {:ok, p} = Profiles.create_business(c, %{name: "Acme Ltd"})
    assert p["type"] == "business"
  end

  test "update_personal/3 puts to /v1/profiles/:id", %{bypass: b, config: c} do
    stub_put(b, "/v1/profiles/1", @profile)
    assert {:ok, p} = Profiles.update_personal(c, 1, %{firstName: "Bob"})
    assert p["id"] == 1
  end

  test "update_business/3 puts to /v1/profiles/:id/business", %{bypass: b, config: c} do
    stub_put(b, "/v1/profiles/2/business", @business)
    assert {:ok, p} = Profiles.update_business(c, 2, %{name: "Acme Updated"})
    assert p["type"] == "business"
  end

  test "returns WiseError on 404", %{bypass: b, config: c} do
    stub_error(b, "GET", "/v1/profiles/999", 404, %{message: "Not found"})
    assert {:error, err} = Profiles.get(c, 999)
    assert Error.not_found?(err)
  end

  test "returns WiseError on 403 SCA_REQUIRED", %{bypass: b, config: c} do
    stub_error(b, "GET", "/v1/profiles", 403, %{code: "SCA_REQUIRED"})
    assert {:error, err} = Profiles.list(c)
    assert Error.sca_required?(err)
  end
end
