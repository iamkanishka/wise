defmodule Wise.ErrorTest do
  use ExUnit.Case, async: true

  alias Wise.Error

  describe "Error.message/1" do
    test "formats all fields" do
      err = %Error{
        type: :api,
        status_code: 422,
        code: "VALIDATION_ERROR",
        message: "Bad input",
        errors: [],
        request_id: nil
      }

      msg = Error.message(err)
      assert msg =~ "422"
      assert msg =~ "VALIDATION_ERROR"
      assert msg =~ "Bad input"
    end

    test "formats without optional fields" do
      err = %Error{type: :api, status_code: 404, errors: []}
      msg = Error.message(err)
      assert msg =~ "404"
    end
  end

  describe "type predicates" do
    test "not_found?/1" do
      assert Error.not_found?(%Error{status_code: 404, errors: []})
      refute Error.not_found?(%Error{status_code: 422, errors: []})
    end

    test "sca_required?/1" do
      assert Error.sca_required?(%Error{status_code: 403, code: "SCA_REQUIRED", errors: []})
      refute Error.sca_required?(%Error{status_code: 403, code: "FORBIDDEN", errors: []})
      refute Error.sca_required?(%Error{status_code: 403, errors: []})
    end

    test "rate_limited?/1" do
      assert Error.rate_limited?(%Error{status_code: 429, errors: []})
      assert Error.rate_limited?(%Error{type: :rate_limited, errors: []})
      refute Error.rate_limited?(%Error{status_code: 422, errors: []})
    end

    test "unauthorized?/1" do
      assert Error.unauthorized?(%Error{status_code: 401, errors: []})
      refute Error.unauthorized?(%Error{status_code: 403, errors: []})
    end

    test "server_error?/1" do
      assert Error.server_error?(%Error{status_code: 500, errors: []})
      assert Error.server_error?(%Error{status_code: 503, errors: []})
      refute Error.server_error?(%Error{status_code: 422, errors: []})
    end

    test "network_error?/1" do
      assert Error.network_error?(%Error{type: :network, errors: []})
      refute Error.network_error?(%Error{type: :api, errors: []})
    end

    test "circuit_open?/1" do
      assert Error.circuit_open?(%Error{type: :circuit_open, errors: []})
      refute Error.circuit_open?(%Error{type: :api, errors: []})
    end
  end

  describe "field_errors/1" do
    test "returns errors list" do
      err = %Error{errors: [%{field: "currency", code: "INVALID", message: "bad"}]}
      assert [%{field: "currency"}] = Error.field_errors(err)
    end

    test "returns empty list when no errors" do
      assert [] = Error.field_errors(%Error{errors: [], type: :api})
    end

    test "returns empty list when errors is nil" do
      assert [] = Error.field_errors(%Error{errors: nil})
    end
  end

  describe "constructors" do
    test "from_response/3 parses body" do
      body = %{
        "code" => "VALIDATION_ERROR",
        "message" => "bad",
        "errors" => [%{"field" => "f", "code" => "c", "message" => "m"}]
      }

      err = Error.from_response(body, 422, "req-123")
      assert err.status_code == 422
      assert err.code == "VALIDATION_ERROR"
      assert err.message == "bad"
      assert err.request_id == "req-123"
      assert length(err.errors) == 1
      assert hd(err.errors).field == "f"
    end

    test "network/1 builds network error" do
      err = Error.network("connection refused")
      assert err.type == :network
      assert err.message == "connection refused"
      assert err.errors == []
    end

    test "circuit_open/1 builds circuit open error" do
      err = Error.circuit_open(30_000)
      assert err.type == :circuit_open
      assert err.message =~ "30s"
    end

    test "invalid_signature/0 builds signature error" do
      err = Error.invalid_signature()
      assert err.type == :invalid_signature
    end
  end

  test "Error is a proper exception with raise" do
    err = %Error{type: :api, status_code: 404, message: "Not found", errors: []}
    assert_raise Wise.Error, fn -> raise err end
  end
end
