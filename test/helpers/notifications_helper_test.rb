# frozen_string_literal: true

require "test_helper"

class NotificationsHelperTest < ActionView::TestCase
  CASES = {
    "listing_approved" => { "title" => "Test GPU" },
    "listing_rejected" => { "title" => "Test GPU", "reason" => "Unclear photos" },
    "new_sale" => { "title" => "Test GPU", "number" => "PCM-2026-000001",
                    "total_cents" => 15_000, "currency" => "EUR" },
    "order_shipped" => { "number" => "PCM-2026-000001" },
    "order_delivered" => { "number" => "PCM-2026-000001" },
    "order_cancelled" => { "number" => "PCM-2026-000001" },
    "price_drop" => { "title" => "Test GPU", "store_name" => "Test store",
                      "price_cents" => 15_000, "currency" => "EUR" },
    "followed_store_new_listing" => { "store_name" => "Test store", "title" => "Test GPU" },
    "saved_search_match" => { "name" => "My search", "title" => "Test GPU" }
  }.freeze

  test "every kind resolves in all six locales without raising" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        CASES.each do |kind, params|
          assert I18n.exists?("notifications.messages.#{kind}", locale),
                 "missing #{kind} in #{locale}"

          notification = Notification.new(kind: kind, params: params)
          message = notification_message(notification)

          assert message.present?, "#{kind} rendered a blank message in #{locale}"
          assert_not_equal I18n.t("notifications.messages.default"), message,
                           "#{kind} fell back to the default message in #{locale}"
        end
      end
    end
  end

  test "price_cents is formatted as money" do
    notification = Notification.new(kind: "price_drop", params: CASES["price_drop"])

    I18n.with_locale(:en) do
      assert_includes notification_message(notification), "150"
      assert_includes notification_message(notification), "€"
    end
  end

  test "a missing translation falls back to the default message" do
    notification = Notification.new(kind: "new_sale", params: { "number" => "PCM-1" })

    assert_equal I18n.t("notifications.messages.default"), notification_message(notification)
  end
end
