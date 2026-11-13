# frozen_string_literal: true

require "test_helper"

class ApiV1GoogleSessionsTest < ActionDispatch::IntegrationTest
  def google_payload(overrides = {})
    {
      "sub" => "google-sub-123",
      "email" => "google-user@example.com",
      "email_verified" => true,
      "given_name" => "Google",
      "family_name" => "User",
      "name" => "Google User"
    }.merge(overrides.transform_keys(&:to_s))
  end

  test "signs in a new user with a valid Google ID token" do
    payload = google_payload

    with_stub(Google::Auth::IDTokens, :verify_oidc,
              ->(_token, aud: nil) { payload }) do
      post api_v1_google_sessions_path, params: { id_token: "valid-id-token" }, as: :json
    end

    assert_response :created
    assert json_data["access_token"].present?
    user = User.find_by!(email: "google-user@example.com")
    assert_equal "google_oauth2", user.provider
    assert_equal "google-sub-123", user.uid
    assert user.confirmed?
  end

  test "links an existing verified account" do
    user = users(:confirmed)
    payload = google_payload(email: user.email)

    with_stub(Google::Auth::IDTokens, :verify_oidc,
              ->(_token, aud: nil) { payload }) do
      post api_v1_google_sessions_path, params: { id_token: "valid-id-token" }, as: :json
    end

    assert_response :created
    assert_equal "google-sub-123", user.reload.uid
  end

  test "rejects an invalid Google ID token" do
    with_stub(Google::Auth::IDTokens, :verify_oidc,
              ->(_token, aud: nil) { raise Google::Auth::IDTokens::VerificationError, "bad" }) do
      post api_v1_google_sessions_path, params: { id_token: "bad" }, as: :json
    end

    assert_response :unauthorized
    assert_equal I18n.t("api.auth.invalid_google_token", locale: :es),
                 json.dig("error", "message")
  end

  test "rejects an unverified Google email without creating a user" do
    payload = google_payload(email_verified: false)

    with_stub(Google::Auth::IDTokens, :verify_oidc,
              ->(_token, aud: nil) { payload }) do
      post api_v1_google_sessions_path, params: { id_token: "unverified" }, as: :json
    end

    assert_response :forbidden
    assert_equal I18n.t("api.auth.email_unverified", locale: :es),
                 json.dig("error", "message")
    assert_not User.exists?(email: "google-user@example.com")
  end

  test "does not link an unverified Google email to an existing account" do
    user = users(:confirmed)
    payload = google_payload(email: user.email, email_verified: false)

    with_stub(Google::Auth::IDTokens, :verify_oidc,
              ->(_token, aud: nil) { payload }) do
      post api_v1_google_sessions_path, params: { id_token: "unverified" }, as: :json
    end

    assert_response :forbidden
    assert_nil user.reload.uid
    assert_nil user.provider
  end
end
