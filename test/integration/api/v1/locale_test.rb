# frozen_string_literal: true

require "test_helper"

class ApiV1LocaleTest < ActionDispatch::IntegrationTest
  test "errors use Accept-Language on public endpoints" do
    get api_v1_listing_path("does-not-exist"), headers: {
      "Accept-Language" => "fr-FR,fr;q=0.9"
    }, as: :json

    assert_response :not_found
    assert_equal I18n.t("api.errors.not_found", locale: :fr), json.dig("error", "message")
  end

  test "errors use Accept-Language for authentication failures" do
    get api_v1_me_path, headers: { "Accept-Language" => "de" }, as: :json

    assert_response :unauthorized
    assert_equal I18n.t("api.errors.unauthorized", locale: :de),
                 json.dig("error", "message")
  end

  test "errors fall back to the user locale when no header is sent" do
    user = users(:confirmed)
    user.update_columns(locale: "it")
    _session, token, = issue_api_session(user)

    get api_v1_order_path(999_999), headers: api_headers(token), as: :json

    assert_response :not_found
    assert_equal I18n.t("api.errors.not_found", locale: :it),
                 json.dig("error", "message")
  end
end
