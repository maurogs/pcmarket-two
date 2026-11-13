# frozen_string_literal: true

require "test_helper"

class SessionsTest < ActionDispatch::IntegrationTest
  test "a confirmed user can sign in and sign out" do
    post user_session_path(locale: :en), params: {
      user: { email: users(:confirmed).email, password: "Password123!" }
    }

    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_includes response.body, I18n.t("account.menu.logout", locale: :en)

    delete destroy_user_session_path(locale: :en)

    assert_response :redirect
    follow_redirect!
    assert_includes response.body, I18n.t("account.menu.signed_out.sign_in", locale: :en)
  end

  test "a banned user cannot sign in" do
    post user_session_path(locale: :en), params: {
      user: { email: users(:banned).email, password: "Password123!" }
    }

    assert_response :redirect
    follow_redirect!

    assert_includes response.body,
                    I18n.t("devise.failure.banned", locale: :en)
  end

  test "the Google button is hidden when the provider is not configured" do
    get new_user_session_path(locale: :en)

    assert_response :success
    assert_not_includes response.body, I18n.t("auth.google", locale: :en)
  end
end
