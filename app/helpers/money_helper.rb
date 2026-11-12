# frozen_string_literal: true

module MoneyHelper
  def money(cents, currency: "EUR")
    return if cents.nil?

    unit = currency.to_s == "EUR" ? "€" : currency.to_s
    number_to_currency(BigDecimal(cents) / 100, unit: unit)
  end
end
