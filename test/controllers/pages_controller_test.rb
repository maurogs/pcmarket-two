require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  MODERN_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/131.0.0.0 Safari/537.36"

  test "GET / returns 200" do
    get "/", headers: { "User-Agent" => MODERN_USER_AGENT }

    assert_response :success
  end

  test "GET /en returns 200 and the English tagline" do
    get "/en", headers: { "User-Agent" => MODERN_USER_AGENT }

    assert_response :success
    assert_includes response.body, I18n.t("app.tagline", locale: :en)
  end

  test "GET /fr returns 200" do
    get "/fr", headers: { "User-Agent" => MODERN_USER_AGENT }

    assert_response :success
  end

  test "uses Accept-Language when no locale cookie is set" do
    get "/", headers: {
      "User-Agent" => MODERN_USER_AGENT,
      "Accept-Language" => "de-DE,de;q=0.9"
    }

    assert_response :success
    assert_includes response.body, I18n.t("app.tagline", locale: :de)
  end
end
