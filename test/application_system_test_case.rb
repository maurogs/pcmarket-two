# frozen_string_literal: true

require "test_helper"

# Browser-driven smoke tests. test_helper already loads the fixtures, Devise
# helpers and the WebMock configuration; the app and the browser talk to each
# other over localhost, which WebMock allows.
WebMock.disable_net_connect!(allow_localhost: true)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ] do |options|
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    # Chrome normally advertises en-US, which would switch the app away from
    # its default Spanish locale. Keep the browser in Spanish like the app.
    options.add_argument("--lang=es-ES")
    options.add_preference("intl.accept_languages", "es-ES,es")
  end

  Capybara.default_max_wait_time = 5
  Capybara.save_path = Rails.root.join("tmp/screenshots")

  # Signs in through the real Devise form, like a visitor would.
  def sign_in_as(user, password: "Password123!")
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    click_button I18n.t("auth.sign_in.submit")
  end

  # The banner is fixed to the bottom of the viewport and can cover links or
  # buttons in short pages, so tests accept it before interacting with the UI.
  def accept_cookie_consent
    return unless page.has_css?("[data-cookie-consent-target='banner']")

    click_button I18n.t("cookie_consent.banner.accept")
    assert_no_selector "[data-cookie-consent-target='banner']"
  end

  def reset_browser_session
    Capybara.reset_sessions!
  end
end
