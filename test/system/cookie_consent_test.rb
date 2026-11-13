# frozen_string_literal: true

require "application_system_test_case"

class CookieConsentTest < ApplicationSystemTestCase
  test "rejecting all hides the banner and it stays hidden after reload" do
    visit root_path

    assert_selector "[data-cookie-consent-target='banner']"
    assert_text I18n.t("cookie_consent.banner.title")

    click_button I18n.t("cookie_consent.banner.reject")

    assert_no_selector "[data-cookie-consent-target='banner']"
    assert_no_text I18n.t("cookie_consent.banner.title")

    page.refresh

    assert_no_selector "[data-cookie-consent-target='banner']"
    assert_no_text I18n.t("cookie_consent.banner.title")
  end
end
