# frozen_string_literal: true

require "test_helper"

class Phase7bSeedsTest < ActiveSupport::TestCase
  test "regions seed loads the launch regions idempotently" do
    load Rails.root.join("db/seeds/regions.rb")
    counts = Region.group(:country_code).count

    assert_equal 14, counts["FR"]
    assert_equal 4, counts["GB"]
    assert_equal 16, counts["DE"]
    assert_equal 20, counts["IT"]
    assert_equal 20, counts["PT"]
    assert_includes Region.where(country_code: "PT").pluck(:name), "Açores"

    assert_no_difference "Region.count" do
      load Rails.root.join("db/seeds/regions.rb")
    end
  end

  test "feature seeds define descriptions for every flag" do
    load Rails.root.join("db/seeds/features.rb")

    FeatureFlag.find_each do |flag|
      assert_predicate flag.description_key, :present?
      assert_not_equal I18n.t("admin.features.no_description", locale: :en),
                       I18n.t(flag.description_key, locale: :en, default: I18n.t("admin.features.no_description", locale: :en))
    end
  end
end
