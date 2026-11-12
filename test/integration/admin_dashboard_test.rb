# frozen_string_literal: true

require "test_helper"

class AdminDashboardTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "the dashboard shows live KPI values" do
    get admin_root_path(locale: :en)

    assert_response :success

    expected = {
      pending_listings: Listing.where(status: "pending_review").count,
      published_today: Listing.published.where(published_at: Time.current.beginning_of_day..).count,
      published_last_7_days: Listing.published.where(published_at: 7.days.ago..).count,
      new_users_today: User.where(created_at: Time.current.beginning_of_day..).count,
      new_users_last_7_days: User.where(created_at: 7.days.ago..).count,
      active_stores: Store.active.count,
      published_listings: Listing.published.count
    }

    expected.each do |key, value|
      assert_includes response.body, %(data-kpi="#{key}"), "missing KPI #{key}"
      assert_match(/data-kpi="#{key}"[^>]*>#{value}</, response.body)
    end
  end

  test "the dashboard lists the oldest pending listing first" do
    get admin_root_path(locale: :en)

    assert_response :success
    assert_includes response.body, listings(:pending_gpu).title
    assert_includes response.body, I18n.t("admin.dashboard.oldest_pending.title", locale: :en)
  end
end
