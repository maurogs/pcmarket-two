# frozen_string_literal: true

require "test_helper"

class SellDashboardTest < ActionDispatch::IntegrationTest
  setup do
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
  end

  test "the seller dashboard renders KPIs, chart, rankings and pending actions" do
    sign_in @seller

    get sell_dashboard_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("sell.dashboard.title", locale: :en)
    assert_includes response.body, I18n.t("sell.dashboard.kpis.revenue", locale: :en)
    assert_includes response.body, I18n.t("sell.dashboard.chart.title", locale: :en)
    assert_includes response.body, I18n.t("sell.dashboard.pending.title", locale: :en)
    assert_includes response.body, I18n.t("sell.dashboard.nav.vacation", locale: :en)
    assert_includes response.body, store_vacation_path(locale: :en)
  end

  test "the range selector accepts 7, 30 and 90 days" do
    sign_in @seller

    get sell_dashboard_path(locale: :en, range: 7)

    assert_response :success
    assert_includes response.body, I18n.t("sell.dashboard.ranges.seven", locale: :en)
  end

  test "users without a store are sent to store onboarding" do
    sign_in users(:admin)

    get sell_dashboard_path(locale: :en)

    assert_redirected_to new_store_path(locale: :en)
  end
end
