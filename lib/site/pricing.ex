defmodule Site.Pricing do
  @moduledoc """
  The hosted instance's prices, as constants.

  These are the values the fountain deployment reads from its environment
  (`CREDIT_*` and `SANDBOX_*`, home-cloud `platform/fountain-site/patches/
  deployment.yaml`). The page used to read them from the running app so it
  could not quote a number the meter did not charge (ADR 0030); now that it is
  static, changing a price means changing it in both places. `test/pricing_test.exs`
  compares this file against the live pricing copy so a drift fails CI.
  """

  @doc "Whether the pricing sections render. The hosted instance bills, so yes."
  def enabled?, do: true

  @doc "The same shape `Fountain.Credits.price_card/0` returns, in cents."
  def price_card do
    %{turn_hour: 25, number_month: 500, inbox_month: 200, email_message: 1, sms_message: 2}
  end

  @doc "The packs a tenant can buy, in cents (`CREDIT_PACKS_CENTS`)."
  def packs, do: [1_000, 2_500, 10_000]

  @doc "The opening credit and its lifetime (`CREDIT_OPENING_CENTS`, `CREDIT_OPENING_DAYS`)."
  def opening, do: {500, 14}

  @doc "The concurrency rule's inputs (`SANDBOX_RESERVE_CENTS`, `SANDBOX_CAP_FLOOR`, `SANDBOX_CAP_CEILING`)."
  def settings, do: %{reserve_cents: 200, cap_floor: 2, cap_ceiling: 20}

  @doc "Cents as `$D.CC`, exactly as the app formats them."
  def format_cents(cents) when is_integer(cents) do
    sign = if cents < 0, do: "-", else: ""
    abs = abs(cents)
    "#{sign}$#{div(abs, 100)}.#{String.pad_leading(Integer.to_string(rem(abs, 100)), 2, "0")}"
  end
end
