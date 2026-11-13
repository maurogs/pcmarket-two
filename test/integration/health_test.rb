# frozen_string_literal: true

require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "up reports a healthy database" do
    get "/up"

    assert_response :success
    assert_equal "ok", JSON.parse(response.body)["status"]
    assert_equal "ok", JSON.parse(response.body)["database"]
  end

  test "up returns 503 when the database is unreachable" do
    with_stub(ActiveRecord::Base, :connection_pool,
              -> { raise ActiveRecord::ConnectionNotEstablished }) do
      get "/up"
    end

    assert_response :service_unavailable
    assert_equal "unavailable", JSON.parse(response.body)["status"]
  end
end
