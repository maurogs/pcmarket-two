# frozen_string_literal: true

require "test_helper"

class NotificationsServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:moderator)
    clear_enqueued_jobs
  end

  test "records a data-only notification" do
    notification = Notifications.record(
      recipient: @user,
      kind: "new_sale",
      notifiable: listings(:published_gpu),
      params: { number: "PCM-1", title: "GPU" }
    )

    assert notification.persisted?
    assert_equal "new_sale", notification.kind
    assert_equal({ "number" => "PCM-1", "title" => "GPU" }, notification.params)
    assert_equal listings(:published_gpu), notification.notifiable
  end

  test "respects the in-app preference" do
    NotificationPreference.create!(user: @user, kind: "new_sale", in_app: false, email: true)

    assert_no_difference -> { Notification.count } do
      assert_nil Notifications.record(recipient: @user, kind: "new_sale", params: {})
    end
  end

  test "accepts preloaded preferences" do
    NotificationPreference.create!(user: @user, kind: "new_sale", in_app: false, email: false)
    preferences = NotificationPreference.settings_for(@user)

    assert_nil Notifications.record(recipient: @user, kind: "new_sale", params: {},
                                    preferences: preferences)
    assert_not Notifications.deliver_email?(@user, "new_sale", preferences: preferences)
  end

  test "deliver_email? honours the email preference" do
    assert Notifications.deliver_email?(@user, "price_drop")

    NotificationPreference.create!(user: @user, kind: "price_drop", in_app: true, email: false)

    assert_not Notifications.deliver_email?(@user, "price_drop")
    assert_not Notifications.deliver_email?(nil, "price_drop")
  end

  test "returns nil for a blank recipient" do
    assert_nil Notifications.record(recipient: nil, kind: "new_sale", params: {})
  end
end
