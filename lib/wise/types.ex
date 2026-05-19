defmodule Wise.Types do
  @moduledoc """
  Shared type definitions for the Wise Platform API.

  All domain types are represented as plain maps with atom keys.
  This module documents the shapes used throughout the library.
  """

  @typedoc "Wise profile ID"
  @type profile_id :: pos_integer()

  @typedoc "Wise transfer ID"
  @type transfer_id :: pos_integer()

  @typedoc "Wise balance ID"
  @type balance_id :: pos_integer()

  @typedoc "Wise recipient account ID"
  @type recipient_id :: pos_integer()

  @typedoc "Wise user ID"
  @type user_id :: pos_integer()

  @typedoc "Wise address ID"
  @type address_id :: pos_integer()

  @typedoc "Wise quote UUID"
  @type quote_id :: String.t()

  @typedoc "Wise batch group ID"
  @type batch_group_id :: String.t()

  @typedoc "Wise webhook subscription ID"
  @type webhook_subscription_id :: String.t()

  @typedoc "Wise card token"
  @type card_token :: String.t()

  @typedoc "Wise card order ID"
  @type card_order_id :: String.t()

  @typedoc "Wise dispute ID"
  @type dispute_id :: String.t()

  @typedoc "Wise KYC review ID"
  @type kyc_review_id :: String.t()

  @typedoc "Wise support case ID"
  @type case_id :: String.t()

  @typedoc "Money amount with currency"
  @type amount :: %{value: number(), currency: String.t()}

  @typedoc "Pagination parameters"
  @type page_params :: %{
          optional(:limit) => pos_integer(),
          optional(:offset) => non_neg_integer(),
          optional(:cursor) => String.t()
        }

  @typedoc "Profile type: personal or business"
  @type profile_type :: :personal | :business

  @typedoc "Balance type"
  @type balance_type :: :STANDARD | :SAVINGS

  @typedoc "Card status"
  @type card_status :: :ACTIVE | :INACTIVE | :FROZEN | :BLOCKED

  @typedoc "Card type"
  @type card_type :: :PHYSICAL | :VIRTUAL

  @typedoc "Transfer status"
  @type transfer_status ::
          :draft
          | :pending_customer_input
          | :processing
          | :funds_converted
          | :outgoing_payment_sent
          | :canceled
          | :funds_refunded
          | :bounced_back
          | :charged_back

  @typedoc "Webhook event type"
  @type webhook_event_type ::
          String.t()

  @typedoc "Successful API result"
  @type result(t) :: {:ok, t} | {:error, Wise.Error.t()}

  @typedoc "Successful API result with no body"
  @type ok_result :: {:ok, :ok} | {:error, Wise.Error.t()}
end
