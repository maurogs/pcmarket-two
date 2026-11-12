# frozen_string_literal: true

require "test_helper"

class Messages::SafetyScannerTest < ActiveSupport::TestCase
  test "detects email addresses" do
    assert_includes Messages::SafetyScanner.call("Email me at seller@example.com"), "email"
  end

  test "detects phone numbers with separators and country code" do
    assert_includes Messages::SafetyScanner.call("Call +34 600 123 456"), "phone"
    assert_includes Messages::SafetyScanner.call("Mi número es 600-123-456"), "phone"
  end

  test "detects IBANs" do
    assert_includes Messages::SafetyScanner.call("IBAN ES91 2100 0418 4502 0005 1332"), "iban"
  end

  test "detects external payment words in several languages" do
    [
      "bizum",
      "transferencia",
      "virement",
      "überweisung",
      "bonifico",
      "transferência",
      "western union",
      "paypal friends",
      "friends and family"
    ].each do |term|
      assert_includes Messages::SafetyScanner.call("Podemos usar #{term}"), "external_payment",
                      "expected #{term} to be flagged"
    end
  end

  test "does not flag ordinary prices" do
    [ "450 €", "1.250 €", "Precio 99 euros", "I can pay 450 EUR" ].each do |body|
      assert_empty Messages::SafetyScanner.call(body), "expected #{body.inspect} to be safe"
    end
  end

  test "returns multiple reasons at once" do
    reasons = Messages::SafetyScanner.call("Paga por Bizum al 600 123 456 o a test@example.com")

    assert_equal %w[email phone external_payment].sort, reasons.sort
  end
end
