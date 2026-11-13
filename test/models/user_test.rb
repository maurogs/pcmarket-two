# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with a username, email, password and accepted terms" do
    assert build_user.valid?
  end

  test "requires a username" do
    user = build_user(username: nil)

    assert_not user.valid?
    assert user.errors[:username].any?
  end

  test "username must be 3 to 30 characters" do
    assert_not build_user(username: "ab").valid?
    assert_not build_user(username: "a" * 31).valid?
    assert build_user(username: "a" * 30).valid?
  end

  test "username only allows letters, numbers, hyphens and underscores" do
    assert_not build_user(username: "bad name!").valid?
    assert build_user(username: "good_Name-123").valid?
  end

  test "username is unique case-insensitively" do
    user = build_user(username: "MAURO")

    assert_not user.valid?
    assert user.errors[:username].any?
  end

  test "banned users cannot authenticate" do
    user = users(:banned)

    assert_not user.active_for_authentication?
    assert_equal :banned, user.inactive_message
  end

  test "soft-deleted users cannot authenticate" do
    user = users(:deleted)

    assert_not user.active_for_authentication?
    assert_equal :deleted, user.inactive_message
  end

  test "confirmed active users can authenticate" do
    assert users(:confirmed).active_for_authentication?
  end

  test "from_omniauth creates a confirmed user linked to the provider" do
    auth = omniauth_hash(email: "oauth-new@example.com", nickname: "oauth_new", uid: "uid-1")

    assert_difference("User.count", 1) do
      @user = Users::FromOmniauth.new(auth).call
    end

    assert_equal "google_oauth2", @user.provider
    assert_equal "uid-1", @user.uid
    assert_equal "oauth_new", @user.username
    assert @user.confirmed?
    assert @user.terms_accepted_at.present?
    assert @user.valid?
  end

  test "from_omniauth links an existing account by email" do
    existing = users(:confirmed)
    auth = omniauth_hash(email: existing.email, nickname: "ignored", uid: "uid-2")

    assert_no_difference("User.count") do
      @user = Users::FromOmniauth.new(auth).call
    end

    assert_equal existing, @user
    assert_equal "google_oauth2", @user.provider
    assert_equal "uid-2", @user.uid
  end

  test "from_omniauth returns the same user on subsequent calls" do
    auth = omniauth_hash(email: "oauth-repeat@example.com", nickname: "oauth_repeat", uid: "uid-3")

    first = Users::FromOmniauth.new(auth).call
    assert_no_difference("User.count") do
      assert_equal first, Users::FromOmniauth.new(auth).call
    end
  end

  test "from_omniauth refuses to link an existing account when the email is not verified" do
    existing = users(:confirmed)

    [ false, nil ].each do |verified|
      auth = omniauth_hash(email: existing.email, nickname: "ignored",
                           uid: "uid-unverified-#{verified.inspect}", email_verified: verified)

      assert_no_difference("User.count") do
        @user = Users::FromOmniauth.new(auth).call
      end

      assert_equal existing, @user
      assert @user.errors[:email].any?
      assert_nil @user.provider
      assert_nil @user.uid
    end

    existing.reload
    assert_nil existing.provider
    assert_nil existing.uid
  end

  test "from_omniauth links an existing account when raw_info reports a verified email" do
    existing = users(:confirmed)
    auth = omniauth_hash(email: existing.email, nickname: "ignored", uid: "uid-raw-info",
                         email_verified: nil, extra: { raw_info: { email_verified: true } })

    assert_no_difference("User.count") do
      @user = Users::FromOmniauth.new(auth).call
    end

    assert_equal existing, @user
    assert_equal "google_oauth2", @user.provider
    assert_equal "uid-raw-info", @user.uid
  end

  test "from_omniauth signs in an already linked user when email_verified is absent" do
    first = Users::FromOmniauth.new(
      omniauth_hash(email: "oauth-linked@example.com", nickname: "oauth_linked", uid: "uid-linked")
    ).call

    second = Users::FromOmniauth.new(
      omniauth_hash(email: "oauth-linked@example.com", nickname: "oauth_linked",
                    uid: "uid-linked", email_verified: nil)
    ).call

    assert_equal first, second
    assert_empty second.errors
  end

  private

  def build_user(attributes = {})
    User.new({
      username: "new_user",
      email: "new_user@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      terms_accepted: "1"
    }.merge(attributes))
  end

  def omniauth_hash(email:, nickname:, uid:, email_verified: true, extra: {})
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: {
        email: email,
        first_name: "OAuth",
        last_name: "User",
        nickname: nickname,
        email_verified: email_verified
      },
      extra: extra
    )
  end
end
