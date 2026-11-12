# frozen_string_literal: true

require "test_helper"

class OmniauthCallbacksTest < ActionDispatch::IntegrationTest
  setup do
    @previous_test_mode = OmniAuth.config.test_mode
    @previous_mock_auth = OmniAuth.config.mock_auth[:google_oauth2]
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = @previous_test_mode
    OmniAuth.config.mock_auth[:google_oauth2] = @previous_mock_auth
  end

  test "an unverified email for an existing account redirects to sign in with an alert" do
    existing = users(:confirmed)
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-callback-unverified",
      info: {
        email: existing.email,
        first_name: "OAuth",
        last_name: "User",
        nickname: "oauth_callback",
        email_verified: false
      }
    )
    OmniAuth.config.mock_auth[:google_oauth2] = auth

    # The Google strategy is only registered when credentials are present, so
    # in test the mock_auth hash is injected into the Rack env directly. The
    # request still goes through the real route and controller.
    post user_google_oauth2_omniauth_callback_path,
         env: { "omniauth.auth" => auth }

    assert_redirected_to new_user_session_path(locale: I18n.locale)
    assert_equal I18n.t("auth.omniauth_email_not_verified"), flash[:alert]

    existing.reload
    assert_nil existing.provider
    assert_nil existing.uid
  end

  test "a verified email links the Google identity to the existing account" do
    existing = users(:confirmed)
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-callback-verified",
      info: {
        email: existing.email,
        first_name: "OAuth",
        last_name: "User",
        nickname: "oauth_callback",
        email_verified: true
      }
    )
    OmniAuth.config.mock_auth[:google_oauth2] = auth

    post user_google_oauth2_omniauth_callback_path,
         env: { "omniauth.auth" => auth }

    assert_redirected_to root_path(locale: I18n.locale)
    assert_nil flash[:alert]

    existing.reload
    assert_equal "google_oauth2", existing.provider
    assert_equal "uid-callback-verified", existing.uid
  end
end
