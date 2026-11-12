# frozen_string_literal: true

require "test_helper"

class NotificationPreferenceTest < ActiveSupport::TestCase
  setup do
    @user = users(:moderator)
  end

  test "defaults to in-app and email enabled without a database row" do
    preference = NotificationPreference.for(user: @user, kind: "new_sale")

    assert preference.new_record?
    assert preference.in_app?
    assert preference.email?
    assert_equal 0, @user.notification_preferences.count
  end

  test "for returns the persisted row when it exists" do
    stored = NotificationPreference.create!(user: @user, kind: "new_sale",
                                            in_app: false, email: false)

    assert_equal stored, NotificationPreference.for(user: @user, kind: "new_sale")
    assert_not NotificationPreference.in_app?(@user, "new_sale")
    assert_not NotificationPreference.email?(@user, "new_sale")
  end

  test "for accepts a preloaded hash and array" do
    stored = NotificationPreference.create!(user: @user, kind: "new_sale",
                                            in_app: false, email: true)
    settings = NotificationPreference.settings_for(@user)

    assert_equal stored, NotificationPreference.for(user: @user, kind: "new_sale",
                                                    preferences: settings)
    assert_equal stored, NotificationPreference.for(user: @user, kind: "new_sale",
                                                    preferences: [ stored ])
    assert_not NotificationPreference.in_app?(@user, "new_sale", preferences: settings)
    assert NotificationPreference.email?(@user, "new_sale", preferences: settings)
  end

  test "settings_for returns every kind with its stored or default values" do
    NotificationPreference.create!(user: @user, kind: "new_sale", in_app: false, email: false)

    settings = NotificationPreference.settings_for(@user)

    assert_equal Notification::KINDS.sort, settings.keys.sort
    assert_not settings["new_sale"].in_app?
    assert_not settings["new_sale"].email?
    assert settings["order_shipped"].in_app?
    assert settings["order_shipped"].email?
  end

  test "in_app? and email? default to true for anonymous and new users" do
    assert_not NotificationPreference.email?(nil, "new_sale")
    assert NotificationPreference.in_app?(nil, "new_sale")
    assert NotificationPreference.in_app?(@user, "order_shipped")
    assert NotificationPreference.email?(@user, "order_shipped")
  end

  test "marketing kinds require the explicit marketing opt-in" do
    with_marketing_kinds([ "promotion" ]) do
      assert NotificationPreference.marketing_kind?("promotion")

      @user.update!(marketing_opt_in: false)
      assert_not NotificationPreference.email?(@user, "promotion")

      @user.update!(marketing_opt_in: true)
      assert NotificationPreference.email?(@user, "promotion")
    end
  end

  private

  def with_marketing_kinds(kinds)
    original = Notification::MARKETING_KINDS
    Notification.send(:remove_const, :MARKETING_KINDS)
    Notification.const_set(:MARKETING_KINDS, kinds.freeze)
    yield
  ensure
    Notification.send(:remove_const, :MARKETING_KINDS)
    Notification.const_set(:MARKETING_KINDS, original)
  end
end
