defmodule Wise do
  @moduledoc """
  Production-grade Elixir client for the Wise Platform API.

  ## Installation

  Add `wise` to your `mix.exs` dependencies:

      def deps do
        [{:wise, "~> 1.0"}]
      end

  ## Quick Start

      # Build a config
      config = Wise.Config.new!(
        personal_token: System.fetch_env!("WISE_API_TOKEN"),
        sandbox: true
      )

      # Use any service
      {:ok, profiles} = Wise.Services.Profiles.list(config)
      {:ok, quote}    = Wise.Services.Quotes.create(config, profile_id, %{
        sourceCurrency: "USD",
        targetCurrency: "GBP",
        sourceAmount:   1000
      })
      {:ok, transfer} = Wise.Services.Transfers.create(config, %{
        targetAccount:         recipient_id,
        quoteUuid:             quote["id"],
        customerTransactionId: Wise.IdempotencyKey.new()
      })
      {:ok, _funded}  = Wise.Services.Transfers.fund(config, profile_id, transfer["id"])

  ## Error Handling

      case Wise.Services.Transfers.fund(config, pid, tid) do
        {:ok, result}                                    -> result
        {:error, %Wise.Error{code: "SCA_REQUIRED"}}      -> redirect_to_sca()
        {:error, %Wise.Error{type: :circuit_open}}       -> handle_open_circuit()
        {:error, %Wise.Error{type: :network, message: m}} -> Logger.warn(m)
      end

  ## All 42 API Groups

  | Module | Description |
  |---|---|
  | `Wise.Services.Profiles` | Personal & business profiles |
  | `Wise.Services.Quotes` | Rate locking & fee calculation |
  | `Wise.Services.Recipients` | Beneficiary account management |
  | `Wise.Services.Transfers` | Payment creation & funding |
  | `Wise.Services.Balances` | Multi-currency balances |
  | `Wise.Services.Statements` | JSON/CSV/PDF/XLSX/MT940 statements |
  | `Wise.Services.BankAccounts` | Receive-money bank details |
  | `Wise.Services.Batches` | Batch payments (up to 1,000) |
  | `Wise.Services.DirectDebits` | ACH/EFT funding accounts |
  | `Wise.Services.Rates` | Mid-market exchange rates |
  | `Wise.Services.Currencies` | Supported currencies |
  | `Wise.Services.Comparisons` | Multi-provider price comparison |
  | `Wise.Services.Cards` | Card status, permissions, PCI data |
  | `Wise.Services.CardOrders` | Physical and virtual card ordering |
  | `Wise.Services.CardTransactions` | Card transaction history |
  | `Wise.Services.SpendLimits` | Per-card & per-profile limits |
  | `Wise.Services.SpendControls` | MCC & transaction-type controls |
  | `Wise.Services.Disputes` | Card transaction disputes |
  | `Wise.Services.KioskCollection` | On-site card production |
  | `Wise.Services.PushProvisioning` | Apple/Google Pay provisioning |
  | `Wise.Services.ThreeDS` | 3D Secure challenge results |
  | `Wise.Services.Webhooks` | Subscription management & verification |
  | `Wise.Services.Activities` | Profile activity log |
  | `Wise.Services.Addresses` | Profile address management |
  | `Wise.Services.Contacts` | Find profiles by Wisetag/email/phone |
  | `Wise.Services.KYC` | Evidence upload & verification |
  | `Wise.Services.KYCReview` | Hosted & API-based KYC reviews |
  | `Wise.Services.OAuth` | OAuth 2.0 token exchange |
  | `Wise.Services.OTT` | One Time Token SCA (deprecated) |
  | `Wise.Services.SCA` | Strong Customer Authentication |
  | `Wise.Services.Cases` | Partner support case management |
  | `Wise.Services.MCA` | Multi Currency Account |
  | `Wise.Services.Users` | User account management |
  | `Wise.Services.UserSecurity` | PIN, FaceMap, phone, device setup |
  | `Wise.Services.FaceTec` | Biometric public key retrieval |
  | `Wise.Services.JOSE` | JWS/JWE key management |
  | `Wise.Services.ClaimAccount` | Account claim code generation |
  | `Wise.Services.Simulations` | Sandbox state simulation |

  ## Advanced Features

    - **Rate limiting** — token-bucket GenServer (10 req/s, burst 20)
    - **Circuit breaker** — CLOSED/OPEN/HALF_OPEN state machine GenServer
    - **Retry** — exponential back-off with cryptographic jitter (`:crypto.strong_rand_bytes/1`)
    - **Request/response hooks** — telemetry, logging, custom headers
    - **HMAC-SHA256 webhook verification** — constant-time comparison
    - **Connection pooling** — hackney pool via `Wise.Application`
    - **OTP supervision** — started automatically as part of the application tree
  """

  alias Wise.Services.Currencies

  @doc """
  Checks API connectivity. Returns `:ok` or `{:error, Wise.Error.t()}`.
  """
  @spec ping(Wise.Config.t()) :: :ok | {:error, Wise.Error.t()}
  @spec ping(Wise.Config.t()) :: :ok | {:error, Wise.Error.t()}
  def ping(config) do
    case Currencies.list(config) do
      {:ok, _} -> :ok
      error -> error
    end
  end
end
