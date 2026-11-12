# frozen_string_literal: true

require "test_helper"

class ApiV1EnvelopeTest < ActionDispatch::IntegrationTest
  test "collections use the data and meta envelope with pagination headers" do
    get api_v1_listings_path, params: { per_page: 1 }, as: :json

    assert_response :success
    assert json["data"].is_a?(Array)
    assert_equal 1, json_meta["per_page"]
    assert_equal 1, json_meta["page"]
    assert_operator json_meta["total"], :>=, 1
    assert_operator json_meta["total_pages"], :>=, 1
    assert_equal json_meta["total"].to_s, response.headers["X-Total-Count"]
    assert_includes response.headers["Link"], 'rel="first"'
    assert_includes response.headers["Link"], 'rel="last"'
  end

  test "single resources use only the data envelope" do
    get api_v1_listing_path(listings(:published_gpu).slug), as: :json

    assert_response :success
    assert json.key?("data")
    assert_not json.key?("meta")
    assert_equal listings(:published_gpu).id, json_data["id"]
    assert json_data["specs"].is_a?(Array)
    assert json_data["delivery_estimate"].present?
    assert json_data["similar_listing_ids"].is_a?(Array)
  end

  test "errors use the code, message and details envelope" do
    get api_v1_listing_path("missing-listing"), as: :json

    assert_response :not_found
    assert_equal %w[code details message], json.fetch("error").keys.sort
    assert_equal "not_found", json.dig("error", "code")
  end

  test "per_page is capped at 50" do
    get api_v1_listings_path, params: { per_page: 500 }, as: :json

    assert_response :success
    assert_equal 50, json_meta["per_page"]
  end

  test "public listing detail supports conditional GET" do
    get api_v1_listing_path(listings(:published_gpu).slug), as: :json
    assert_response :success
    etag = response.headers["ETag"]
    assert etag.present?

    get api_v1_listing_path(listings(:published_gpu).slug),
        headers: { "If-None-Match" => etag }, as: :json

    assert_response :not_modified
  end

  test "CORS is enabled for API paths only" do
    get api_v1_listings_path, headers: { "Origin" => "https://app.example" }, as: :json
    assert_response :success
    assert_equal "*", response.headers["Access-Control-Allow-Origin"]

    get root_path(locale: :en), headers: { "Origin" => "https://app.example" }
    assert_nil response.headers["Access-Control-Allow-Origin"]
  end
end
