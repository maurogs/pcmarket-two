# frozen_string_literal: true

require "test_helper"

class AdminImpersonationTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    sign_in users(:admin)
  end

  test "an admin can impersonate a regular user, see the banner and stop" do
    target = users(:confirmed)

    post admin_impersonation_path(locale: :en), params: { user_id: target.id }

    assert_redirected_to root_path(locale: :en)
    assert_equal "impersonation.started", AdminAuditLog.last.action
    assert_equal users(:admin), AdminAuditLog.last.actor

    get root_path(locale: :en)
    assert_response :success
    assert_includes response.body, I18n.t("admin.impersonation.banner", locale: :en, name: target.display_name)

    delete admin_impersonation_path(locale: :en)

    assert_redirected_to admin_user_path(target, locale: :en)
    assert_equal "impersonation.stopped", AdminAuditLog.last.action
  end

  test "impersonated sessions cannot reach admin or payment settings" do
    target = users(:confirmed)

    post admin_impersonation_path(locale: :en), params: { user_id: target.id }

    get admin_root_path(locale: :en)
    assert_response :not_found

    get store_payment_path(locale: :en)
    assert_redirected_to root_path(locale: :en)
    assert_equal I18n.t("admin.impersonation.payment_blocked", locale: :en), flash[:alert]
  end

  test "impersonated sessions cannot change security settings, delete the account or export data" do
    target = users(:confirmed)

    post admin_impersonation_path(locale: :en), params: { user_id: target.id }
    alert = I18n.t("admin.impersonation.account_blocked", locale: :en)

    assert_no_difference "User.count" do
      post account_deletion_path(locale: :en), params: { current_password: "Password123!" }
    end
    assert_redirected_to root_path(locale: :en)
    assert_equal alert, flash[:alert]
    assert_nil target.reload.deleted_at

    patch account_password_path(locale: :en), params: {
      user: { current_password: "Password123!", password: "NewPassword123!",
              password_confirmation: "NewPassword123!" }
    }
    assert_redirected_to root_path(locale: :en)
    assert_equal alert, flash[:alert]
    assert target.reload.valid_password?("Password123!")

    patch account_profile_path(locale: :en), params: {
      section: "email", user: { email: "changed@example.com" }
    }
    assert_redirected_to root_path(locale: :en)
    assert_equal alert, flash[:alert]
    assert_equal "mauro@example.com", target.reload.email

    assert_no_enqueued_jobs do
      post account_data_export_path(locale: :en)
    end
    assert_redirected_to root_path(locale: :en)
    assert_equal alert, flash[:alert]

    get account_data_export_path(locale: :en, token: "signed-token")
    assert_redirected_to root_path(locale: :en)
    assert_equal alert, flash[:alert]
  end

  test "an admin cannot impersonate another admin or themselves" do
    post admin_impersonation_path(locale: :en), params: { user_id: users(:admin).id }

    assert_redirected_to admin_user_path(users(:admin), locale: :en)
    assert_equal I18n.t("admin.impersonation.cannot", locale: :en), flash[:alert]
  end

  test "non-admins cannot start an impersonation" do
    sign_out users(:admin)
    sign_in users(:moderator)

    post admin_impersonation_path(locale: :en), params: { user_id: users(:confirmed).id }

    assert_response :not_found
  end
end
