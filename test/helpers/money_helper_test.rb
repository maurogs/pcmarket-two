# frozen_string_literal: true

require "test_helper"

class MoneyHelperTest < ActiveSupport::TestCase
  include ActionView::Helpers::NumberHelper
  include MoneyHelper

  test "formats cents as euros using the current locale" do
    formatted = money(12_345)

    assert_includes formatted, "€"
    assert_includes formatted, "123"
  end

  test "accepts a different currency and handles nil" do
    assert_includes money(1_000, currency: "USD"), "10"
    assert_nil money(nil)
  end

  test "uses the locale currency format" do
    I18n.with_locale(:es) do
      assert_equal "123,45 €", money(12_345)
    end

    I18n.with_locale(:en) do
      assert_equal "€123.45", money(12_345)
    end
  end
end
