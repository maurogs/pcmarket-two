# frozen_string_literal: true

require "test_helper"

class SpanishTaxIdValidatorTest < ActiveSupport::TestCase
  class Probe
    include ActiveModel::Model

    attr_accessor :tax_id

    validates :tax_id, spanish_tax_id: true
  end

  test "accepts valid NIF numbers" do
    assert valid?("12345678Z")
    assert valid?("12345678z")
    assert valid?("12.345.678-Z")
  end

  test "rejects NIF numbers with the wrong control letter" do
    assert_not valid?("12345678A")
    assert_not valid?("1234567Z")
  end

  test "accepts valid NIE numbers" do
    assert valid?("X1234567L")
    assert valid?("Y1234567X")
    assert valid?("Z1234567R")
  end

  test "rejects NIE numbers with the wrong control letter" do
    assert_not valid?("X1234567X")
    assert_not valid?("A1234567L")
  end

  test "accepts valid CIF numbers with digit and letter control characters" do
    assert valid?("B12345674")
    assert valid?("P1234567D")
  end

  test "rejects CIF numbers with an invalid control character" do
    assert_not valid?("B12345678")
    assert_not valid?("P1234567A")
  end

  test "rejects blank and malformed values" do
    assert_not valid?("")
    assert_not valid?("not-a-tax-id")
  end

  private

  def valid?(value)
    Probe.new(tax_id: value).valid?
  end
end
