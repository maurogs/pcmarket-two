# frozen_string_literal: true

require "test_helper"

class ApiV1ListingSearchParityTest < ActionDispatch::IntegrationTest
  test "the API returns the same listing ids and order as ListingSearch" do
    params = { q: "RTX", condition: [ "used_good" ], sort: "price_asc", per_page: 24 }
    expected = ListingSearch.new(params).call

    get api_v1_listings_path, params: params, as: :json

    assert_response :success
    assert_equal expected.listings.map(&:id), json_data.map { |listing| listing["id"] }
    assert_equal expected.total_count, json_meta["total"]
    assert_equal expected.facets[:conditions], json_meta["facets"]["conditions"]
    assert_equal expected.facets[:attributes], json_meta["facets"]["attributes"]
  end

  test "invalid filters are ignored exactly like the web search" do
    params = {
      min_price: "-5", max_price: "not-a-number", sort: "nonsense",
      condition: [ "not-a-condition" ], page: "0", per_page: "999"
    }
    expected = ListingSearch.new(params).call

    get api_v1_listings_path, params: params, as: :json

    assert_response :success
    assert_equal expected.listings.map(&:id), json_data.map { |listing| listing["id"] }
    assert_equal 50, json_meta["per_page"]
  end
end
