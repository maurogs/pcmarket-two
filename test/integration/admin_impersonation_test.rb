# frozen_string_literal: true

require "test_helper"

class AdminImpersonationTest < ActionDispatch::IntegrationTest
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
