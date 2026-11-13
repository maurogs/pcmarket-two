# frozen_string_literal: true

require "test_helper"

class FlipperAccessTest < ActionDispatch::IntegrationTest
  test "non-admin users are blocked from the Flipper UI" do
    sign_in users(:confirmed)

    get "/admin/flipper"

    assert_response :not_found
  end

  test "admins can open the Flipper UI" do
    sign_in users(:admin)

    get "/admin/flipper"
    follow_redirect!

    assert_response :success
  end
end
