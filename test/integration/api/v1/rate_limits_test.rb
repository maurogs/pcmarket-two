# frozen_string_literal: true

require "test_helper"

class ApiV1RateLimitsTest < ActionDispatch::IntegrationTest
  test "sign-in attempts are throttled per IP with Retry-After and the error envelope" do
    10.times do
      post api_v1_sessions_path, params: {
        email: users(:confirmed).email, password: "wrong"
      }, as: :json
      assert_response :unauthorized
    end

    post api_v1_sessions_path, params: {
      email: users(:confirmed).email, password: "wrong"
    }, as: :json

    assert_response :too_many_requests
    assert_operator response.headers["Retry-After"].to_i, :>, 0
    assert_equal "rate_limited", json.dig("error", "code")
    assert_equal I18n.t("api.errors.rate_limited", locale: :es),
                 json.dig("error", "message")
  end

  test "sign-ups are throttled per IP" do
    5.times do |index|
      post api_v1_registrations_path, params: {
        user: {
          username: "throttle_user_#{index}",
          email: "throttle-#{index}@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          locale: "es",
          country_code: "ES",
          terms_accepted: "1"
        }
      }, as: :json
      assert_response :created
    end

    post api_v1_registrations_path, params: {
      user: {
        username: "throttle_user_last",
        email: "throttle-last@example.com",
        password: "Password123!",
        password_confirmation: "Password123!",
        locale: "es",
        country_code: "ES",
        terms_accepted: "1"
      }
    }, as: :json

    assert_response :too_many_requests
    assert_operator response.headers["Retry-After"].to_i, :>, 0
    assert_equal "rate_limited", json.dig("error", "code")
  end

  test "HTML sign-in is throttled too" do
    10.times do
      post "/users/sign_in", params: {
        user: { email: users(:confirmed).email, password: "wrong" }
      }
      assert_response :unprocessable_content
    end

    post "/users/sign_in", params: {
      user: { email: users(:confirmed).email, password: "wrong" }
    }

    assert_response :too_many_requests
    assert_operator response.headers["Retry-After"].to_i, :>, 0
  end
end
