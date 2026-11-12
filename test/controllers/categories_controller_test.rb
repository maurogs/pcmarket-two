# frozen_string_literal: true

require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "renders a category page with visible listings" do
    get "/en/c/graphics-cards"

    assert_response :success
    assert_includes response.body, "Graphics Cards"
    assert_includes response.body, "NVIDIA GeForce RTX 4070 Ti Super"
    assert_includes response.body, "AMD Radeon RX 7800 XT"
    assert_not_includes response.body, "Pending Review GPU"
    assert_includes response.body, I18n.t("listings.filters.title", locale: :en)
    assert_includes response.body, 'action="/en/c/graphics-cards"'
  end

  test "applies filters from the query string" do
    get "/en/c/graphics-cards?condition%5B%5D=used_good"

    assert_response :success
    assert_includes response.body, "AMD Radeon RX 7800 XT"
    assert_not_includes response.body, "NVIDIA GeForce RTX 4070 Ti Super"
  end

  test "marks filtered category URLs as noindex,follow with an unfiltered canonical" do
    get "/en/c/graphics-cards?condition%5B%5D=used_good&sort=price_asc"

    assert_response :success
    assert_includes response.body, '<meta name="robots" content="noindex,follow">'
    assert_includes response.body,
                    '<link rel="canonical" href="http://www.example.com/en/c/graphics-cards">'
  end

  test "paginates with a self-referencing canonical on page two" do
    insert_bulk_listings(categories(:gpus), count: 25)

    get "/en/c/graphics-cards?page=2"

    assert_response :success
    assert_includes response.body,
                    '<link rel="canonical" href="http://www.example.com/en/c/graphics-cards?page=2">'
    assert_not_includes response.body, '<meta name="robots" content="noindex'
  end

  test "renders hreflang alternates and x-default" do
    get "/en/c/graphics-cards"

    assert_response :success
    I18n.available_locales.each do |locale|
      assert_includes response.body, %(hreflang="#{locale}")
    end
    assert_includes response.body, 'hreflang="x-default"'
  end

  test "renders BreadcrumbList and ItemList JSON-LD" do
    get "/en/c/graphics-cards"

    assert_response :success
    assert_includes response.body, '"@type":"BreadcrumbList"'
    assert_includes response.body, '"@type":"ItemList"'
  end

  test "sets public cache headers for anonymous category responses" do
    get "/en/c/graphics-cards"

    assert_response :success
    assert_equal "max-age=60, public", response.headers["Cache-Control"]
  end

  test "redirects an old category slug permanently" do
    category = Category.create!(name_en: "History Category", position: 99, active: true)
    old_slug = category.slug
    category.update!(slug: "#{old_slug}-renamed")

    get "/en/c/#{old_slug}"

    assert_response :moved_permanently
    assert_redirected_to "/en/c/#{old_slug}-renamed"
  end

  test "returns 404 for an inactive category" do
    categories(:gpus).update_columns(active: false)

    get "/en/c/graphics-cards"

    assert_response :not_found
  end
end
