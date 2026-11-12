# frozen_string_literal: true

require "test_helper"

class AdminUsersTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    sign_in users(:admin)
  end

  test "moderators can read the user directory but cannot mutate accounts" do
    sign_out users(:admin)
    sign_in users(:moderator)

    get admin_users_path(locale: :en)
    assert_response :success

    get admin_user_path(users(:confirmed), locale: :en)
    assert_response :success

    assert_no_changes -> { users(:confirmed).reload.banned_at } do
      post admin_user_ban_path(users(:confirmed), locale: :en), params: { reason: "Nope" }
    end
    assert_response :redirect
  end

  test "the index supports search and status filters" do
    get admin_users_path(locale: :en, q: "banned@example.com")

    assert_response :success
    assert_includes response.body, users(:banned).email
    assert_not_includes response.body, users(:confirmed).email

    get admin_users_path(locale: :en, status: "deleted")

    assert_response :success
    assert_includes response.body, users(:deleted).email
    assert_not_includes response.body, users(:confirmed).email
  end

  test "the index filters by role and store ownership" do
    get admin_users_path(locale: :en, role: "moderator")
    assert_includes response.body, users(:moderator).email
    assert_not_includes response.body, users(:confirmed).email

    get admin_users_path(locale: :en, has_store: "true")
    assert_includes response.body, users(:confirmed).email
    assert_not_includes response.body, users(:moderator).email
  end

  test "CSV export contains the filtered users" do
    get admin_users_path(locale: :en, role: "admin", format: :csv)

    assert_response :success
    assert_match %r{text/csv}, response.media_type
    assert_includes response.body, users(:admin).email
    assert_not_includes response.body, users(:confirmed).email
  end

  test "the show page renders the profile, store and audit sections" do
    get admin_user_path(users(:confirmed), locale: :en)

    assert_response :success
    assert_includes response.body, users(:confirmed).email
    assert_includes response.body, CGI.escapeHTML(stores(:confirmed_store).name)
    assert_includes response.body, I18n.t("admin.users.show.audit_title", locale: :en)
  end

  test "banning archives live listings, expires pending checkouts and emails the user" do
    user = users(:confirmed)
    listing = listings(:published_gpu)
    checkout = create_order!(buyer: user, status: "pending_payment").checkout

    assert_emails 1 do
      assert_difference "AdminAuditLog.count", 1 do
        post admin_user_ban_path(user, locale: :en), params: { reason: "Fraudulent activity" }
      end
    end

    assert_redirected_to admin_user_path(user, locale: :en)
    assert user.reload.banned?
    assert_equal "Fraudulent activity", user.ban_reason
    assert_equal "archived", listing.reload.status
    assert_equal "expired", checkout.reload.status
    assert_equal "user.banned", AdminAuditLog.last.action
  end

  test "unbanning clears the ban fields" do
    user = users(:banned)

    delete admin_user_ban_path(user, locale: :en)

    assert_redirected_to admin_user_path(user, locale: :en)
    assert_not user.reload.banned?
    assert_nil user.ban_reason
  end

  test "an admin cannot demote themselves" do
    admin = users(:admin)

    post admin_user_role_path(admin, locale: :en), params: { role: "user" }

    assert_redirected_to admin_user_path(admin, locale: :en)
    assert admin.reload.admin?
    assert_equal I18n.t("admin.users.flash.role_change_failed", locale: :en), flash[:alert]
  end

  test "the last admin cannot be demoted" do
    admin = users(:admin)

    post admin_user_role_path(admin, locale: :en), params: { role: "moderator" }

    assert admin.reload.admin?
  end

  test "another user's role can be changed" do
    user = users(:seller_two)

    post admin_user_role_path(user, locale: :en), params: { role: "moderator" }

    assert_redirected_to admin_user_path(user, locale: :en)
    assert user.reload.moderator?
    assert_equal "user.role_changed", AdminAuditLog.last.action
  end

  test "staff can confirm an email manually" do
    user = users(:seller_two)
    user.update_columns(confirmed_at: nil, confirmation_token: "token")

    post admin_user_confirmation_path(user, locale: :en)

    assert_redirected_to admin_user_path(user, locale: :en)
    assert_not_nil user.reload.confirmed_at
  end

  test "staff can resend the confirmation and request a password reset" do
    user = users(:seller_two)
    user.update_columns(confirmed_at: nil, confirmation_token: "token")

    assert_emails 1 do
      post admin_user_confirmation_resend_path(user, locale: :en)
    end

    assert_emails 1 do
      post admin_user_password_reset_path(user, locale: :en)
    end
  end

  test "soft deletion anonymises the account through Accounts::Delete" do
    user = users(:seller_two)
    listing = listings(:suspended_listing)

    post admin_user_deletion_path(user, locale: :en)

    assert_redirected_to admin_user_path(user, locale: :en)
    assert user.reload.soft_deleted?
    assert_equal "archived", listing.reload.status
    assert_equal "user.deleted", AdminAuditLog.last.action
  end

  test "profile fields can be edited" do
    user = users(:seller_two)

    patch admin_user_path(user, locale: :en),
          params: { user: { first_name: "Sofia", last_name: "Updated", phone: "600111222" } }

    assert_redirected_to admin_user_path(user, locale: :en)
    assert_equal "Updated", user.reload.last_name
    assert_equal "user.updated", AdminAuditLog.last.action
  end
end
