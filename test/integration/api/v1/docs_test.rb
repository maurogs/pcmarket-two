# frozen_string_literal: true

require "test_helper"

class ApiDocsTest < ActionDispatch::IntegrationTest
  test "renders the pinned Redoc page" do
    get api_docs_path

    assert_response :success
    assert_includes response.body, "redoc@2.1.5"
    assert_includes response.body, "/api/v1/openapi.yaml"
  end

  test "Redoc is not loaded anywhere else" do
    get root_path(locale: :en)

    assert_response :success
    assert_not_includes response.body, "redoc"
  end
end
