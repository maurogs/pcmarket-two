# frozen_string_literal: true

require "test_helper"

class CookieConsentsTest < ActionDispatch::IntegrationTest
  def payload
    JSON.parse(cookies[CookieConsent::COOKIE_NAME])
  end

  test "shows the consent banner before a choice is made" do
    get root_path

    assert_response :success
    assert_includes response.body, I18n.t("cookie_consent.banner.title")
    assert_includes response.body, I18n.t("cookie_consent.modal.title")
    assert_includes response.body, 'data-consent="analytics"'
  end

  test "accepting all stores the categories and hides the banner" do
    post cookie_consent_path, params: {
      cookie_consent: {
        necessary: "true",
        preferences: "true",
        analytics: "true",
        marketing: "true"
      }
    }

    assert_redirected_to root_path
    assert_equal true, payload.dig("categories", "analytics")
    assert_equal true, payload.dig("categories", "marketing")
    assert_equal true, payload.dig("categories", "necessary")
    assert_equal CookieConsent::VERSION, payload["version"]
    assert payload["timestamp"].present?

    get root_path
    assert_response :success
    assert_not_includes response.body, I18n.t("cookie_consent.banner.title")
  end

  test "rejecting all keeps only necessary cookies" do
    post cookie_consent_path, params: {
      cookie_consent: { analytics: "false", marketing: "false", preferences: "false" }
    }

    assert_equal true, payload.dig("categories", "necessary")
    assert_equal false, payload.dig("categories", "analytics")
    assert_equal false, payload.dig("categories", "marketing")
    assert_equal false, payload.dig("categories", "preferences")
  end

  test "signed-in users get an audit record" do
    sign_in users(:confirmed)

    assert_difference "CookieConsent.count", 1 do
      post cookie_consent_path, params: {
        cookie_consent: { analytics: "true", marketing: "false", preferences: "true" }
      }
    end

    consent = CookieConsent.last
    assert_equal users(:confirmed), consent.user
    assert_equal true, consent.categories["analytics"]
    assert_equal CookieConsent::VERSION, consent.version
    assert consent.consented_at.present?
  end

  test "guests do not create an audit record" do
    assert_no_difference "CookieConsent.count" do
      post cookie_consent_path, params: { cookie_consent: { analytics: "true" } }
    end
  end
end
