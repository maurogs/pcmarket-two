# frozen_string_literal: true

require "test_helper"

class CookieConsentHelperTest < ActionView::TestCase
  include ApplicationHelper

  def cookies
    @cookies ||= {}
  end

  test "necessary is always consented to" do
    assert consented_to?(:necessary)
  end

  test "reads categories from the consent cookie" do
    cookies[CookieConsent::COOKIE_NAME] = {
      "categories" => { "necessary" => true, "analytics" => true, "marketing" => false },
      "version" => CookieConsent::VERSION
    }.to_json

    assert consented_to?(:analytics)
    assert_not consented_to?(:marketing)
    assert_not consented_to?(:preferences)
  end

  test "malformed consent cookies are treated as opt-out" do
    cookies[CookieConsent::COOKIE_NAME] = "not json"

    assert_not consented_to?(:analytics)
    assert consented_to?(:necessary)
  end
end
