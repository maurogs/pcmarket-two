# frozen_string_literal: true

require "test_helper"

class HelpPagesTest < ActionDispatch::IntegrationTest
  test "help centre lists guides and FAQ categories" do
    get help_pages_path

    assert_response :success
    assert_includes response.body, I18n.t("help.index.title")
    assert_includes response.body, I18n.t("help.pages.about.title")
    assert_includes response.body, I18n.t("help.pages.shipping.title")
    assert_includes response.body, I18n.t("help.faq.categories.buying.title")
    assert_includes response.body, I18n.t("help.faq.categories.account.title")
  end

  test "each static help page renders with its content" do
    HelpPagesController::SLUGS.each do |slug|
      get help_page_path(slug: slug)
      assert_response :success
      assert_includes response.body, I18n.t("help.pages.#{slug}.title")
      assert_includes response.body, I18n.t("help.pages.about.title")
    end
  end

  test "unknown help pages return 404" do
    get "/help/not-a-page"

    assert_response :not_found
  end

  test "seller fees are free while commissions are disabled" do
    get help_page_path(slug: "seller-fees")

    assert_response :success
    assert_includes response.body, I18n.t("help.fees.free_notice")
  end

  test "help pages are translated" do
    get "/en/help/shipping"

    assert_response :success
    assert_includes response.body, I18n.t("help.pages.shipping.title", locale: :en)
    assert_includes response.body, "Correos"
  end
end
