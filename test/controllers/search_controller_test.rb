# frozen_string_literal: true

require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "renders search results for a query" do
    get "/en/search?q=Radeon"

    assert_response :success
    assert_includes response.body, "Results for “Radeon”"
    assert_includes response.body, "AMD Radeon RX 7800 XT"
    assert_includes response.body, "Tarjeta Gráfica Radeon Usada"
    assert_not_includes response.body, "NVIDIA GeForce RTX 4060 Budget"
  end

  test "marks filtered search results as noindex with an unfiltered canonical" do
    get "/en/search?q=Radeon&sort=price_desc"

    assert_response :success
    assert_includes response.body, '<meta name="robots" content="noindex,follow">'
    assert_includes response.body, '<link rel="canonical" href="http://www.example.com/en/search">'
  end

  test "the unfiltered search page is indexable" do
    get "/en/search"

    assert_response :success
    assert_not_includes response.body, '<meta name="robots" content="noindex'
    assert_includes response.body, '<link rel="canonical" href="http://www.example.com/en/search">'
  end

  test "filters search results by category slug" do
    get "/en/search?category=graphics-cards&condition%5B%5D=used_good"

    assert_response :success
    assert_includes response.body, "AMD Radeon RX 7800 XT"
    assert_not_includes response.body, "Tarjeta Gráfica Radeon Usada"
  end

  test "sets public cache headers for anonymous search responses" do
    get "/en/search"

    assert_response :success
    assert_equal "max-age=60, public", response.headers["Cache-Control"]
  end
end
