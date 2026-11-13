# frozen_string_literal: true

require "test_helper"

class IbanValidatorTest < ActiveSupport::TestCase
  test "accepts valid IBANs with or without spaces" do
    assert IbanValidator.valid?("ES9121000418450200051332")
    assert IbanValidator.valid?("ES91 2100 0418 4502 0005 1332")
    assert IbanValidator.valid?("GB82WEST12345698765432")
    assert IbanValidator.valid?("DE89370400440532013000")
  end

  test "rejects bad checksums, shapes and empty values" do
    assert_not IbanValidator.valid?("ES9121000418450200051333")
    assert_not IbanValidator.valid?("ES91")
    assert_not IbanValidator.valid?("")
    assert_not IbanValidator.valid?(nil)
  end

  test "normalises and exposes the last four digits" do
    assert_equal "ES9121000418450200051332", IbanValidator.normalise("es91 2100 0418 4502 0005 1332")
    assert_equal "1332", IbanValidator.last4("ES91 2100 0418 4502 0005 1332")
  end
end
