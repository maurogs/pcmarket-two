require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  MODERN_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/131.0.0.0 Safari/537.36"

  test "GET /en renders the app shell in English" do
    get "/en", headers: { "User-Agent" => MODERN_USER_AGENT }

    assert_response :success
    assert_match(/<html lang="en"/, response.body)
    assert_includes response.body, I18n.t("nav.list_item", locale: :en)
    assert_includes response.body, I18n.t("nav.search_placeholder", locale: :en)
    assert_includes response.body, I18n.t("nav.categories.label", locale: :en)
    assert_includes response.body, "Components"
    assert_includes response.body, I18n.t("footer.about.title", locale: :en)
    assert_includes response.body, I18n.t("footer.newsletter.title", locale: :en)
  end

  test "the locale switcher links to every supported locale" do
    get "/en", headers: { "User-Agent" => MODERN_USER_AGENT }

    assert_response :success
    assert_includes response.body, 'href="/fr"'
    assert_includes response.body, 'href="/de"'
    assert_includes response.body, 'href="/it"'
    assert_includes response.body, 'href="/pt"'
    assert_includes response.body, 'href="/"'
  end
end
