# frozen_string_literal: true

require "test_helper"

class CountryTest < ActiveSupport::TestCase
  test "active scope returns only active countries ordered by position" do
    assert_equal [ countries(:spain) ], Country.active.to_a
  end

  test "launched_codes returns the active country codes" do
    assert_equal [ "ES" ], Country.launched_codes
  end

  test "launched_codes cache is cleared after a country changes" do
    store = ActiveSupport::Cache::MemoryStore.new

    with_cache(store) do
      assert_equal [ "ES" ], Country.launched_codes

      Country.create!(
        code: "NL", active: true, default_locale: "en", currency: "EUR",
        vat_rate: 19, position: 3
      )

      assert_equal %w[ES NL], Country.launched_codes
    end
  end

  test "name uses the translated country key" do
    I18n.with_locale(:en) do
      assert_equal "Spain", countries(:spain).name
    end
  end
end
