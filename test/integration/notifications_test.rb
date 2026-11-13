# frozen_string_literal: true

require "test_helper"

class NotificationsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:moderator)
    clear_enqueued_jobs
  end

  def notification!(kind: "new_sale", params: {}, **attrs)
    Notification.create!({ recipient: @user, kind: kind, params: params }.merge(attrs))
  end

  test "the bell renders the unread count and the latest ten notifications" do
    12.times { |index| notification!(params: { number: "N#{index}", title: "Item #{index}" }) }
    sign_in @user

    get root_path(locale: :en)

    assert_response :success
    assert_select "#notifications-bell", 1
    assert_select "#notifications-bell ul li", 10
    assert_includes response.body, "9+"
    assert_includes response.body,
                    I18n.t("notifications.bell.unread_count", count: 12, locale: :en)
  end

  test "the inbox paginates and filters unread notifications" do
    20.times { |index| notification!(params: { number: "UNREAD#{index}", title: "Item" }) }
    5.times { |index| notification!(read_at: Time.current, params: { number: "READ#{index}", title: "Item" }) }
    sign_in @user

    get notifications_path(locale: :en)

    assert_response :success
    assert_includes response.body,
                    I18n.t("notifications.index.count", count: 25, locale: :en)
    assert_select "ul.overflow-hidden > li", 20
    assert_select "a", text: "2"

    get notifications_path(filter: "unread", locale: :en)

    assert_response :success
    assert_includes response.body,
                    I18n.t("notifications.index.count", count: 20, locale: :en)
    assert_select "ul.overflow-hidden > li", 20
  end

  test "marking all notifications as read clears the unread count" do
    2.times { notification! }
    sign_in @user

    post notification_read_path(locale: :en)

    assert_redirected_to notifications_path(locale: :en)
    assert_equal I18n.t("notifications.flash.all_read", locale: :en), flash[:notice]
    assert_equal 0, @user.notifications.unread.count
  end

  test "the preferences page persists in-app and email settings" do
    sign_in @user

    get notification_preferences_path(locale: :en)
    assert_response :success
    assert_includes response.body,
                    I18n.t("notifications.preferences.kinds.new_sale", locale: :en)

    patch notification_preferences_path(locale: :en),
          params: {
            notification_preferences: {
              "new_sale" => { "in_app" => "0", "email" => "1" }
            }
          }

    assert_redirected_to notification_preferences_path(locale: :en)
    preference = NotificationPreference.find_by(user: @user, kind: "new_sale")
    assert preference.present?
    assert_not preference.in_app?
    assert preference.email?
  end

  test "the header renders the Turbo broadcast stream tag" do
    sign_in @user

    get root_path(locale: :en)

    assert_response :success
    assert_includes response.body, "turbo-cable-stream-source"
    assert_includes response.body, "signed-stream-name"
  end

  test "a valid unsubscribe GET disables the email alert" do
    token = EmailUnsubscribe.token(user: @user, kind: "price_drop")

    get email_unsubscribe_path(token: token, locale: :en)

    assert_redirected_to root_path(locale: :en)
    assert_equal I18n.t("email_unsubscribe.flash.success", locale: :en), flash[:notice]
    assert_not NotificationPreference.for(user: @user, kind: "price_drop").email?
  end

  test "a one-click unsubscribe POST disables every alert email" do
    token = EmailUnsubscribe.token(user: @user)

    post email_unsubscribe_path(token: token, locale: :en)

    assert_redirected_to root_path(locale: :en)
    assert_equal I18n.t("email_unsubscribe.flash.success", locale: :en), flash[:notice]
    Notification::ALERT_KINDS.each do |kind|
      assert_not NotificationPreference.for(user: @user, kind: kind).email?
    end
  end

  test "an invalid unsubscribe token shows a translated alert" do
    get email_unsubscribe_path(token: "garbage", locale: :en)

    assert_redirected_to root_path(locale: :en)
    assert_equal I18n.t("email_unsubscribe.flash.invalid", locale: :en), flash[:alert]
  end

  test "anonymous users are sent to sign in" do
    get notifications_path(locale: :en)

    assert_redirected_to new_user_session_path(locale: :en)
  end
end
