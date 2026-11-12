# frozen_string_literal: true

require "test_helper"

class ApiV1MeTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:confirmed)
    @token = issue_api_session(@user).at(1)
    @headers = api_headers(@token)
  end

  test "returns the profile with notification preferences" do
    get api_v1_me_path, headers: @headers, as: :json

    assert_response :success
    assert_equal @user.email, json_data["email"]
    assert json_data["notification_preferences"].any?
    assert json_data["notification_preferences"].all? { |preference| preference.key?("kind") }
  end

  test "updates profile attributes, locale and notification preferences" do
    patch api_v1_me_path, headers: @headers, params: {
      user: { first_name: "Mauro", last_name: "Ruiz", locale: "en" },
      notification_preferences: {
        new_message: { in_app: true, email: false }
      }
    }, as: :json

    assert_response :success
    assert_equal "en", json_data["locale"]
    preference = @user.notification_preferences.find_by!(kind: "new_message")
    assert preference.in_app
    assert_not preference.email
  end

  test "requires the current password before deleting the account" do
    delete api_v1_me_path, headers: @headers,
           params: { current_password: "wrong" }, as: :json

    assert_response :unprocessable_content
    assert_equal "validation_failed", json.dig("error", "code")
    assert_nil @user.reload.deleted_at
  end

  test "deletes the account and revokes every API session" do
    delete api_v1_me_path, headers: @headers,
           params: { current_password: "Password123!" }, as: :json

    assert_response :success
    assert json_data["deleted"]
    assert @user.reload.soft_deleted?
    assert @user.api_sessions.where(revoked_at: nil).none?

    get api_v1_me_path, headers: @headers, as: :json
    assert_response :unauthorized
  end

  test "registers and removes device tokens" do
    post api_v1_device_tokens_path, headers: @headers,
         params: { token: "apns-token-123", platform: "ios" }, as: :json
    assert_response :created
    token_id = json_data["id"]
    assert_equal "apns-token-123", json_data["token"]

    delete api_v1_device_token_path(token_id), headers: @headers, as: :json
    assert_response :no_content
    assert_not DeviceToken.exists?(token_id)
  end

  test "cannot remove another user's device token" do
    token = DeviceToken.create!(user: users(:seller_two), token: "other-token",
                                platform: "android")

    delete api_v1_device_token_path(token), headers: @headers, as: :json
    assert_response :not_found
  end
end
