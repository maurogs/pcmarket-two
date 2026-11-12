# frozen_string_literal: true

require "test_helper"

class AddressTest < ActiveSupport::TestCase
  def build_address(overrides = {})
    Address.new({
      user: users(:confirmed),
      full_name: "Mauro Ruiz",
      line1: "Calle Mayor 1",
      city: "Madrid",
      region: regions(:madrid),
      postal_code: "28001",
      country_code: "ES",
      phone: "600000000"
    }.merge(overrides))
  end

  test "accepts a Spanish postal code that matches the province" do
    assert build_address.valid?
  end

  test "rejects a Spanish postal code that does not match the province" do
    address = build_address(postal_code: "46001")

    assert_not address.valid?
    assert_includes address.errors[:postal_code], I18n.t("addresses.errors.postal_code_province")
  end

  test "requires a five-digit Spanish postal code" do
    address = build_address(postal_code: "2800")

    assert_not address.valid?
    assert_includes address.errors[:postal_code], I18n.t("addresses.errors.postal_code_format")
  end

  test "requires a province for Spanish addresses" do
    address = build_address(region: nil)

    assert_not address.valid?
    assert_includes address.errors[:region], I18n.t("addresses.errors.province_required")
  end

  test "rejects a province from another country" do
    address = build_address(country_code: "FR")

    assert_not address.valid?
    assert_includes address.errors[:region], I18n.t("addresses.errors.region_country_mismatch")
  end

  test "allows non-Spanish addresses without a province prefix rule" do
    address = build_address(country_code: "FR", region: regions(:ile_de_france), postal_code: "75001")

    assert address.valid?
  end

  test "only one address per user is the default" do
    first = build_address(default: true)
    first.save!
    second = build_address(default: true)
    second.save!

    assert_not first.reload.default?
    assert second.default?
  end

  test "snapshots the shipping address for an order" do
    snapshot = build_address.to_snapshot

    assert_equal "Calle Mayor 1", snapshot["line1"]
    assert_equal "Madrid", snapshot["province"]
    assert_equal "M", snapshot["region_code"]
    assert_equal "28001", snapshot["postal_code"]
  end
end
