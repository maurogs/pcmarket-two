# frozen_string_literal: true

require "test_helper"

class EmailUnsubscribeTest < ActiveSupport::TestCase
  setup do
    @user = users(:moderator)
    @saved_search = SavedSearch.create!(user: @user, name: "Alerts", query_params: {})
  end

  test "token round trips the user, saved search and kind" do
    token = EmailUnsubscribe.token(user: @user, saved_search: @saved_search,
                                   kind: "saved_search_match")
    data = EmailUnsubscribe.verify(token)

    assert_equal @user.id, data["user_id"]
    assert_equal @saved_search.id, data["saved_search_id"]
    assert_equal "saved_search_match", data["kind"]
  end

  test "invalid or blank tokens return nil" do
    assert_nil EmailUnsubscribe.verify(nil)
    assert_nil EmailUnsubscribe.verify("")
    assert_nil EmailUnsubscribe.verify("not-a-valid-token")
  end

  test "applying a saved-search token disables its email alerts" do
    token = EmailUnsubscribe.token(user: @user, saved_search: @saved_search)

    assert EmailUnsubscribe.apply(EmailUnsubscribe.verify(token))
    assert_not @saved_search.reload.email_alerts?
  end

  test "a generic token disables email for every alert kind and keeps in-app settings" do
    stored = NotificationPreference.create!(user: @user, kind: "price_drop",
                                            in_app: false, email: true)
    token = EmailUnsubscribe.token(user: @user)
    assert EmailUnsubscribe.apply(EmailUnsubscribe.verify(token))

    Notification::ALERT_KINDS.each do |kind|
      preference = NotificationPreference.for(user: @user, kind: kind)
      assert_not preference.email?, "#{kind} email should be disabled"
    end

    assert_not stored.reload.in_app?
    assert_not stored.email?
    defaulted = NotificationPreference.for(user: @user, kind: "followed_store_new_listing")
    assert defaulted.in_app?
  end

  test "applying a token for a missing user returns false" do
    assert_not EmailUnsubscribe.apply("user_id" => -1)
  end
end
