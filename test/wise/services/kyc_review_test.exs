defmodule Wise.Services.KYCReviewTest do
  use ExUnit.Case, async: true
  import Wise.Test.BypassHelpers
  alias Wise.Services.KYCReview

  @review %{
    "id" => "kr-001",
    "profileId" => 1,
    "status" => "WAITING_CUSTOMER_INPUT",
    "link" => "https://wise.com/kyc?token=abc",
    "requirements" => [%{"key" => "PROOF_OF_IDENTITY", "state" => "NOT_PROVIDED"}],
    "createdAt" => "2024-01-01T00:00:00Z",
    "updatedAt" => "2024-01-01T00:00:00Z"
  }

  setup do
    {bypass, config} = setup_bypass()
    %{bypass: bypass, config: config}
  end

  test "create/3 posts to /v1/profiles/:id/kyc-reviews", %{bypass: b, config: c} do
    stub_post(b, "/v1/profiles/1/kyc-reviews", @review, 201)
    assert {:ok, r} = KYCReview.create(c, 1, %{profileId: 1, action: "ONBOARDING"})
    assert r["id"] == "kr-001"
    assert r["status"] == "WAITING_CUSTOMER_INPUT"
  end

  test "list/2 returns reviews", %{bypass: b, config: c} do
    stub_get(b, "/v1/profiles/1/kyc-reviews", [@review])
    assert {:ok, [r]} = KYCReview.list(c, 1)
    assert r["id"] == "kr-001"
  end

  test "update_redirect_url/4 patches and returns link", %{bypass: b, config: c} do
    updated = Map.put(@review, "link", "https://wise.com/kyc?x=y")
    stub_patch(b, "/v1/profiles/1/kyc-reviews/kr-001", updated)
    assert {:ok, r} = KYCReview.update_redirect_url(c, 1, "kr-001", "https://app.com/complete")
    assert r["link"] == "https://wise.com/kyc?x=y"
  end

  test "get_by_id/3 fetches v2 endpoint", %{bypass: b, config: c} do
    approved = Map.put(@review, "status", "APPROVED")
    stub_get(b, "/v2/profiles/1/kyc-reviews/kr-001", approved)
    assert {:ok, r} = KYCReview.get_by_id(c, 1, "kr-001")
    assert r["status"] == "APPROVED"
  end

  test "get_by_id_v1/3 fetches v1 endpoint", %{bypass: b, config: c} do
    stub_get(b, "/v1/profiles/1/kyc-reviews/kr-001", @review)
    assert {:ok, r} = KYCReview.get_by_id_v1(c, 1, "kr-001")
    assert r["id"] == "kr-001"
  end

  test "submit_requirement/4 posts to v2 kyc-requirements", %{bypass: b, config: c} do
    stub_post(b, "/v2/profiles/1/kyc-requirements/PROOF_OF_IDENTITY", %{}, 204)

    assert {:ok, _} =
             KYCReview.submit_requirement(c, 1, "PROOF_OF_IDENTITY", %{documentType: "PASSPORT"})
  end
end
