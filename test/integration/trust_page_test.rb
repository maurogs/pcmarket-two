# frozen_string_literal: true

require "test_helper"

class TrustPageTest < ActionDispatch::IntegrationTest
  test "renders the trust page copy and live figures above the thresholds" do
    stats = { listings_sold: 120, active_sellers: 18, average_rating: 4.7, ratings_count: 12 }

    with_stub(TrustStats, :call, stats) do
      get trust_path
    end

    assert_response :success
    assert_includes response.body, I18n.t("trust.title")
    assert_includes response.body, I18n.t("trust.protection.title")
    assert_includes response.body, I18n.t("trust.safety.title")
    assert_includes response.body, I18n.t("trust.stats.listings_sold")
    assert_includes response.body, I18n.t("trust.stats.active_sellers")
    assert_includes response.body, "4,7"
    assert_includes response.body, I18n.t("trust.faq.title")
    assert_includes response.body, I18n.t("trust.faq.items", locale: :es).last[:question]
  end

  test "hides figures below sensible minimums" do
    stats = { listings_sold: 2, active_sellers: 1, average_rating: 3.2, ratings_count: 2 }

    with_stub(TrustStats, :call, stats) do
      get trust_path
    end

    assert_response :success
    assert_not_includes response.body, I18n.t("trust.stats.listings_sold")
    assert_not_includes response.body, I18n.t("trust.stats.active_sellers")
    assert_not_includes response.body, I18n.t("trust.stats.average_rating", count: 2)
  end

  test "uses the configured buyer protection window" do
    Setting.set(:buyer_protection_days, 5)
    stats = { listings_sold: 120, active_sellers: 18, average_rating: 4.7, ratings_count: 12 }

    with_stub(TrustStats, :call, stats) do
      get trust_path
    end

    assert_includes response.body, I18n.t("trust.protection.steps.inspect.body", days: 5, locale: :es)
  ensure
    Setting.set(:buyer_protection_days, 2)
  end

  test "is translated" do
    stats = { listings_sold: 0, active_sellers: 0, average_rating: 0, ratings_count: 0 }

    with_stub(TrustStats, :call, stats) do
      get "/en/trust"
    end

    assert_response :success
    assert_includes response.body, I18n.t("trust.title", locale: :en)
    assert_includes response.body, "Is PCMarket safe?"
  end
end
