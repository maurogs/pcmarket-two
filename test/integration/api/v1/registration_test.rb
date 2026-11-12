# frozen_string_literal: true

require "test_helper"

class ApiV1RegistrationTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    Setting.set(:api_require_confirmation, true)
  end

  teardown do
    Setting.set(:api_require_confirmation, true)
  end

  test "registers a user, accepts terms and sends a confirmation email" do
    assert_emails 1 do
      post api_v1_registrations_path, params: {
        user: {
          username: "api_new_user",
          email: "api-new@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          first_name: "Api",
          last_name: "User",
          locale: "en",
          country_code: "ES",
          terms_accepted: "1"
        }
      }, as: :json
    end

    assert_response :created
    assert json_data["confirmation_required"]
    assert_equal "api-new@example.com", json_data.dig("user", "email")
    user = User.find_by!(email: "api-new@example.com")
    assert user.terms_accepted_at.present?
    assert_nil user.confirmed_at
  end

  test "registration requires accepting the terms" do
    post api_v1_registrations_path, params: {
      user: {
        username: "api_no_terms",
        email: "api-no-terms@example.com",
        password: "Password123!",
        password_confirmation: "Password123!",
        locale: "es",
        country_code: "ES"
      }
    }, as: :json

    assert_response :unprocessable_content
    assert_equal "validation_failed", json.dig("error", "code")
    assert json.dig("error", "details").key?("terms_accepted")
    assert_not User.exists?(email: "api-no-terms@example.com")
  end

  test "registration returns tokens when confirmation is disabled" do
    Setting.set(:api_require_confirmation, false)

    post api_v1_registrations_path, params: {
      user: {
        username: "api_confirmed_now",
        email: "api-confirmed-now@example.com",
        password: "Password123!",
        password_confirmation: "Password123!",
        locale: "en",
        country_code: "ES",
        terms_accepted: "1"
      }
    }, as: :json

    assert_response :created
    assert json_data["access_token"].present?
    assert_equal "api-confirmed-now@example.com", json_data.dig("user", "email")
  end

  test "password reset always returns the same generic answer" do
    assert_emails 1 do
      post api_v1_password_reset_path, params: { email: users(:confirmed).email }, as: :json
    end

    assert_response :accepted
    assert_equal I18n.t("api.auth.password_reset_sent", locale: :es),
                 json_data["message"]

    assert_no_emails do
      post api_v1_password_reset_path, params: { email: "missing@example.com" }, as: :json
    end
    assert_response :accepted
  end
end
