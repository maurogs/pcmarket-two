# frozen_string_literal: true

require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  test "anonymous visitors are redirected to sign in" do
    get admin_root_path(locale: :en)

    assert_response :redirect
    assert_match "/users/sign_in", response.location
  end

  test "regular users get a 404" do
    sign_in users(:confirmed)

    get admin_root_path(locale: :en)

    assert_response :not_found
  end

  test "moderators and admins can open the dashboard" do
    sign_in users(:moderator)
    get admin_root_path(locale: :en)
    assert_response :success

    sign_out users(:moderator)
    sign_in users(:admin)
    get admin_root_path(locale: :en)
    assert_response :success
  end

  test "the admin layout is not indexed and marks future screens as coming soon" do
    sign_in users(:admin)

    get admin_root_path(locale: :en)

    assert_response :success
    assert_includes response.body, '<meta name="robots" content="noindex,nofollow">'
    assert_includes response.body, 'aria-disabled="true"'
    assert_includes response.body, I18n.t("admin.nav.coming_soon", locale: :en)
    assert_includes response.body, 'href="/admin/flipper"'
    assert_not_includes response.body, I18n.t("announcement.promo", locale: :en)
  end

  test "moderators can open the moderation queue" do
    sign_in users(:moderator)

    get admin_listing_reviews_path(locale: :en)

    assert_response :success
    assert_includes response.body, listings(:pending_gpu).title
  end
end
