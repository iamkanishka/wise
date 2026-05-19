# Wise

Production-grade Elixir client for the [Wise Platform API](https://docs.wise.com/api-reference).

[![Hex.pm](https://img.shields.io/hexpm/v/wise.svg)](https://hex.pm/packages/wise)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Features

- **All 42 Wise API groups** — Profiles, Quotes, Transfers, Balances, Cards, KYC, Webhooks, and more
- **Three auth modes** — Personal Token, OAuth 2.0 Client Credentials, OAuth 2.0 User Token
- **OTP-backed transport** — Token-bucket rate limiter (`GenServer`), circuit breaker (`GenServer`)
- **Retry with crypto jitter** — Exponential back-off using `:crypto.strong_rand_bytes/1`
- **Webhook verification** — HMAC-SHA256 with constant-time comparison (no external deps)
- **Request/response hooks** — Telemetry, structured logging, custom headers
- **Connection pooling** — Hackney pool managed by `Wise.Application`
- **Fully typed** — `@spec`, `@type`, `Dialyxir`-compatible throughout

## Installation

```elixir
def deps do
  [{:wise, "~> 1.0"}]
end
```

## Quick Start

```elixir
# Build a config
config = Wise.Config.new!(
  personal_token: System.fetch_env!("WISE_API_TOKEN"),
  sandbox: true
)

# Ping the API
:ok = Wise.ping(config)

# List profiles
{:ok, profiles} = Wise.Services.Profiles.list(config)

# Create a quote
{:ok, quote} = Wise.Services.Quotes.create(config, profile_id, %{
  sourceCurrency: "USD",
  targetCurrency: "GBP",
  sourceAmount:   1000
})

# Create a recipient
{:ok, recipient} = Wise.Services.Recipients.create(config, %{
  profile:           profile_id,
  accountHolderName: "Alice Smith",
  currency:          "GBP",
  type:              "sort_code",
  details:           %{sortCode: "040075", accountNumber: "12345678"}
})

# Create and fund a transfer
key = Wise.IdempotencyKey.new()
{:ok, transfer} = Wise.Services.Transfers.create(config, %{
  targetAccount:         recipient["id"],
  quoteUuid:             quote["id"],
  customerTransactionId: key
})
{:ok, _} = Wise.Services.Transfers.fund(config, profile_id, transfer["id"])
```

## Error Handling

All service calls return `{:ok, result}` or `{:error, %Wise.Error{}}`:

```elixir
case Wise.Services.Transfers.fund(config, profile_id, transfer_id) do
  {:ok, result} ->
    result

  {:error, %Wise.Error{code: "SCA_REQUIRED"}} ->
    redirect_to_sca_url()

  {:error, %Wise.Error{type: :circuit_open, message: msg}} ->
    Logger.warn("Circuit breaker open: #{msg}")

  {:error, %Wise.Error{type: :network, message: msg}} ->
    Logger.error("Network error: #{msg}")

  {:error, err} when Wise.Error.server_error?(err) ->
    Logger.error("Server error #{err.status_code}")
end
```

### Error predicates

```elixir
Wise.Error.not_found?(err)     # true for HTTP 404
Wise.Error.sca_required?(err)  # true for HTTP 403 + code "SCA_REQUIRED"
Wise.Error.rate_limited?(err)  # true for HTTP 429
Wise.Error.unauthorized?(err)  # true for HTTP 401
Wise.Error.server_error?(err)  # true for HTTP 5xx
Wise.Error.network_error?(err) # true for transport-level failures
Wise.Error.circuit_open?(err)  # true when circuit breaker rejected the request
Wise.Error.field_errors(err)   # [%{field:, code:, message:}] from 422 responses
```

## Authentication

### Personal API Token

```elixir
config = Wise.Config.new!(personal_token: System.fetch_env!("WISE_API_TOKEN"))
```

### OAuth 2.0 — Client Credentials (auto-refresh)

```elixir
config = Wise.Config.new!(
  client_id:     System.fetch_env!("WISE_CLIENT_ID"),
  client_secret: System.fetch_env!("WISE_CLIENT_SECRET"),
  sandbox:       true
)
```

### OAuth 2.0 — User Token with refresh callback

```elixir
config = Wise.Config.new!(
  access_token:     stored_token,
  refresh_token:    stored_refresh,
  token_expires_at: stored_expiry,
  on_token_refresh: fn refresh_token ->
    case MyTokenStore.refresh(refresh_token) do
      {:ok, new_token} -> {:ok, %{access_token: new_token.access, refresh_token: new_token.refresh, expires_at: new_token.expiry}}
      err -> err
    end
  end
)
```

## Advanced Configuration

```elixir
{:ok, rl} = Wise.Internal.RateLimiter.start_link(rate: 10, burst: 20)
{:ok, cb} = Wise.Internal.CircuitBreaker.start_link(
  failure_threshold: 5,
  success_threshold: 2,
  timeout_ms: 30_000
)

config = Wise.Config.new!(
  personal_token: token,
  sandbox:        true,
  timeout:        30_000,
  max_retries:    3,
  retry_base_delay: 500,
  rate_limiter:   rl,
  circuit_breaker: cb,
  request_hooks:  [fn headers -> [{"X-Custom", "value"} | headers] end],
  response_hooks: [fn resp, latency_ms ->
    :telemetry.execute([:wise, :request], %{latency: latency_ms}, %{status: resp.status_code})
  end]
)
```

## Webhooks

```elixir
# Subscription management
{:ok, sub} = Wise.Services.Webhooks.create(config, %{
  name:       "transfers-hook",
  trigger_on: "transfers#state-change",
  url:        "https://yourapp.com/webhooks/wise",
  profile_id: profile_id
})

# In your HTTP handler (Phoenix, Plug, etc.)
def handle_webhook(conn) do
  body   = conn.body_params |> Jason.encode!()
  sig    = get_req_header(conn, "x-signature-sha256") |> List.first("")
  secret = System.fetch_env!("WISE_WEBHOOK_SECRET")

  case Wise.Services.Webhooks.verify_and_parse(body, sig, secret) do
    {:ok, %{"eventType" => "transfers#state-change", "data" => data}} ->
      handle_transfer_state_change(data)
      send_resp(conn, 200, "ok")

    {:error, %Wise.Error{type: :invalid_signature}} ->
      send_resp(conn, 401, "unauthorized")
  end
end
```

## Simulations (Sandbox only)

```elixir
# Advance a transfer through states
{:ok, _} = Wise.Services.Simulations.advance_transfer(config, transfer_id, "processing")
{:ok, _} = Wise.Services.Simulations.advance_transfer(config, transfer_id, "funds_converted")
{:ok, _} = Wise.Services.Simulations.advance_transfer(config, transfer_id, "outgoing_payment_sent")

# Simulate incoming payment
{:ok, _} = Wise.Services.Simulations.simulate_incoming_payment(config, profile_id, balance_id,
  %{value: 1000.00, currency: "GBP"})
```

## All 42 API Groups

| Module                           | Description                                 |
| -------------------------------- | ------------------------------------------- |
| `Wise.Services.Profiles`         | Personal & business profiles                |
| `Wise.Services.Quotes`           | Rate locking & fee calculation              |
| `Wise.Services.Recipients`       | Beneficiary account management              |
| `Wise.Services.Transfers`        | Payment creation & funding                  |
| `Wise.Services.Balances`         | Multi-currency balances                     |
| `Wise.Services.Statements`       | JSON/CSV/PDF/XLSX statements                |
| `Wise.Services.BankAccounts`     | Receive-money bank details                  |
| `Wise.Services.Batches`          | Batch payments (up to 1,000)                |
| `Wise.Services.DirectDebits`     | ACH/EFT funding accounts                    |
| `Wise.Services.Rates`            | Exchange rates                              |
| `Wise.Services.Currencies`       | Supported currencies                        |
| `Wise.Services.Comparisons`      | Multi-provider price comparison             |
| `Wise.Services.Cards`            | Card status & PCI-DSS sensitive data        |
| `Wise.Services.CardOrders`       | Physical & virtual card ordering            |
| `Wise.Services.CardTransactions` | Card transaction history                    |
| `Wise.Services.SpendLimits`      | Per-card & per-profile limits               |
| `Wise.Services.SpendControls`    | MCC & transaction-type controls             |
| `Wise.Services.Disputes`         | Card transaction disputes                   |
| `Wise.Services.KioskCollection`  | On-site card production                     |
| `Wise.Services.PushProvisioning` | Apple/Google Pay provisioning               |
| `Wise.Services.ThreeDS`          | 3D Secure challenge results                 |
| `Wise.Services.Webhooks`         | Subscription management & HMAC verification |
| `Wise.Services.Activities`       | Profile activity log                        |
| `Wise.Services.Addresses`        | Profile address management                  |
| `Wise.Services.Contacts`         | Find profiles by Wisetag/email/phone        |
| `Wise.Services.KYC`              | Evidence upload & verification              |
| `Wise.Services.KYCReview`        | Hosted & API-based KYC reviews              |
| `Wise.Services.OAuth`            | OAuth 2.0 token exchange & refresh          |
| `Wise.Services.OTT`              | One Time Token SCA (deprecated, use SCA)    |
| `Wise.Services.SCA`              | Strong Customer Authentication              |
| `Wise.Services.Cases`            | Partner support case management             |
| `Wise.Services.MCA`              | Multi Currency Account                      |
| `Wise.Services.Users`            | User account management                     |
| `Wise.Services.UserSecurity`     | PIN, FaceMap, phone & device setup          |
| `Wise.Services.FaceTec`          | Biometric public key retrieval              |
| `Wise.Services.JOSE`             | JWS/JWE key management & playground         |
| `Wise.Services.ClaimAccount`     | Account claim code generation               |
| `Wise.Services.Simulations`      | Sandbox state simulation                    |

## Running Tests

```bash
mix deps.get
mix test
mix test --cover   # with coverage
mix credo --strict # linting
mix dialyzer       # type checking
```

## License

MIT — see [LICENSE](LICENSE).
