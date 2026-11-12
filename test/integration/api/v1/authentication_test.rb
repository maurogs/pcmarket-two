# frozen_string_literal: true

require "test_helper"

class ApiV1AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:confirmed)
    @password = "Password123!"
  end

  test "signs in and returns a token pair without storing raw tokens" do
    post api_v1_sessions_path, params: {
      email: @user.email, password: @password, platform: "ios",
      device_name: "iPhone 15", app_version: "1.0.0"
    }, as: :json

    assert_response :created
    data = json_data
    assert data["access_token"].present?
    assert data["refresh_token"].present?
    assert_equal "Bearer", data["token_type"]
    assert_equal @user.email, data.dig("user", "email")
    assert_equal "ios", data.dig("session", "platform")

    session = ApiSession.last
    assert_equal ApiSession.digest(data["access_token"]), session.token_digest
    assert_equal ApiSession.digest(data["refresh_token"]), session.refresh_token_digest
    assert_not_equal data["access_token"], session.token_digest
    assert_operator session.expires_at, :>, 29.days.from_now
    assert_operator session.refresh_expires_at, :>, 89.days.from_now
  end

  test "rejects invalid credentials with the error envelope" do
    post api_v1_sessions_path, params: {
      email: @user.email, password: "wrong", platform: "ios"
    }, as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", json.dig("error", "code")
    assert_equal I18n.t("api.auth.invalid_credentials", locale: :es),
                 json.dig("error", "message")
    assert_nil json["data"]
  end

  test "rejects banned accounts" do
    post api_v1_sessions_path, params: {
      email: users(:banned).email, password: @password
    }, as: :json

    assert_response :forbidden
    assert_equal "forbidden", json.dig("error", "code")
    assert_equal I18n.t("api.auth.banned", locale: :es), json.dig("error", "message")
  end

  test "rejects unconfirmed accounts when confirmation is required" do
    user = User.create!(
      username: "unconfirmed_api", email: "unconfirmed-api@example.com",
      password: @password, password_confirmation: @password,
      locale: "es", country_code: "ES", terms_accepted: "1"
    )

    post api_v1_sessions_path, params: { email: user.email, password: @password },
                               as: :json

    assert_response :forbidden
    assert_equal I18n.t("api.auth.unconfirmed", locale: :es), json.dig("error", "message")
  end

  test "refresh rotates both tokens and a refresh token is single use" do
    _session, access_token, refresh_token = issue_api_session(@user)

    post api_v1_session_refresh_path, params: { refresh_token: refresh_token }, as: :json

    assert_response :success
    new_access = json_data["access_token"]
    new_refresh = json_data["refresh_token"]
    assert_not_equal access_token, new_access
    assert_not_equal refresh_token, new_refresh

    post api_v1_session_refresh_path, params: { refresh_token: refresh_token }, as: :json
    assert_response :unauthorized

    get api_v1_me_path, headers: api_headers(access_token)
    assert_response :unauthorized

    get api_v1_me_path, headers: api_headers(new_access)
    assert_response :success

    post api_v1_session_refresh_path, params: { refresh_token: new_refresh }, as: :json
    assert_response :success
  end

  test "revoking the current session invalidates the access token" do
    _session, access_token, = issue_api_session(@user)

    delete api_v1_current_session_path, headers: api_headers(access_token)
    assert_response :no_content

    get api_v1_me_path, headers: api_headers(access_token)
    assert_response :unauthorized
  end

  test "sliding expiry extends a valid access token" do
    session, access_token, = issue_api_session(@user)
    session.update_columns(expires_at: 1.day.from_now, last_used_at: 1.hour.ago)

    get api_v1_me_path, headers: api_headers(access_token)

    assert_response :success
    assert_operator session.reload.expires_at, :>, 29.days.from_now
    assert_operator session.last_used_at, :>, 1.minute.ago
  end

  test "an expired access token is rejected" do
    session, access_token, = issue_api_session(@user)
    session.update_columns(expires_at: 1.minute.ago)

    get api_v1_me_path, headers: api_headers(access_token)

    assert_response :unauthorized
  end

  test "lists devices and marks the current session" do
    session, access_token, = issue_api_session(@user, device_name: "Current phone")
    issue_api_session(@user, device_name: "Older tablet")

    get api_v1_sessions_path, headers: api_headers(access_token)

    assert_response :success
    assert_equal 2, json_data.size
    current = json_data.find { |entry| entry["id"] == session.id }
    assert current["current"]
    assert_equal "Current phone", current["device_name"]
    assert_equal "2", response.headers["X-Total-Count"]
  end

  test "cannot revoke another user's session" do
    _session, access_token, = issue_api_session(@user)
    other_session, = issue_api_session(users(:seller_two))

    delete api_v1_session_path(other_session), headers: api_headers(access_token)

    assert_response :not_found
    assert_not other_session.reload.revoked?
  end
end
