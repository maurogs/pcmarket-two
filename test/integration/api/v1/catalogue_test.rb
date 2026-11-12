# frozen_string_literal: true

require "test_helper"

class ApiV1CatalogueTest < ActionDispatch::IntegrationTest
  test "returns the cached category tree with active children" do
    get api_v1_categories_path, as: :json

    assert_response :success
    assert json_data.is_a?(Array)
    components = json_data.find { |category| category["slug"] == "components" }
    assert components.present?
    assert components["children"].any? { |child| child["slug"] == "graphics-cards" }
    assert_includes response.headers["Cache-Control"], "max-age=60"
    assert_includes response.headers["Cache-Control"], "public"
  end

  test "returns a category with its effective filters and options" do
    get api_v1_category_path("graphics-cards"), as: :json

    assert_response :success
    data = json_data
    assert_equal "graphics-cards", data.dig("category", "slug")

    chipset = data["filters"].find { |filter| filter["key"] == "gpu_chipset" }
    assert chipset.present?
    assert chipset["attribute_options"].any? { |option| option["value"] == "nvidia" }
    assert_includes data["required_attribute_definition_ids"],
                    attribute_definitions(:gpu_chipset).id
  end

  test "returns attribute definitions, tags, regions and countries" do
    get api_v1_attribute_definitions_path, headers: { "Accept-Language" => "en" }, as: :json
    assert_response :success
    assert json_data.any? { |definition| definition["key"] == "gpu_chipset" }
    assert json_data.first["attribute_options"].is_a?(Array)

    get api_v1_tags_path, as: :json
    assert_response :success
    assert json_data.any? { |tag| tag["slug"] == "verified-seller" }

    get api_v1_regions_path, params: { country: "ES" }, as: :json
    assert_response :success
    assert json_data.any? { |region| region["name"] == "Madrid" }

    get api_v1_countries_path, as: :json
    assert_response :success
    assert_equal [ "ES" ], json_data.map { |country| country["code"] }
  end

  test "returns the public settings and feature flags" do
    Flipper.enable(:offers)
    Flipper.disable(:guest_checkout)

    get api_v1_public_settings_path, as: :json

    assert_response :success
    assert_equal 100, json_data["min_price_cents"]
    assert json_data["features"]["offers"]
    assert_not json_data["features"]["guest_checkout"]
    assert json_data["features"].key?("sell_to_us")
  ensure
    Flipper.disable(:offers)
  end

  test "returns a public storefront and its listings and reviews" do
    store = stores(:confirmed_store)
    get api_v1_store_path(store.slug), as: :json
    assert_response :success
    assert_equal store.id, json_data["id"]
    assert_equal store.name, json_data["name"]

    get api_v1_store_listings_path(store.slug), as: :json
    assert_response :success
    assert json_data.is_a?(Array)
    assert json_data.all? { |listing| listing.dig("store", "id") == store.id }

    get api_v1_store_reviews_path(store.slug), as: :json
    assert_response :success
    assert json_data.is_a?(Array)
  end

  test "returns PC Finder games and recommendations" do
    get api_v1_pc_finder_games_path, as: :json
    assert_response :success
    assert json_data.is_a?(Array)

    get api_v1_pc_finder_recommendations_path,
        params: { game: "cyberpunk-2077", resolution: "1440p", fps: "60" }, as: :json
    assert_response :success
    assert json_data.is_a?(Array)
    assert json_meta["criteria"].present?
  end

  test "returns a published legal page in the negotiated locale" do
    page = LegalPage.new(
      country_code: "ES", locale: "en", kind: "terms", title: "Terms",
      version: "9.0", status: "published",
      published_at: Time.current, effective_at: Time.current
    )
    page.body = "These are the terms."
    page.save!

    get api_v1_legal_page_path("terms"), headers: { "Accept-Language" => "en" }, as: :json

    assert_response :success
    assert_equal "Terms", json_data["title"]
    assert json_data["body_plain"].present?
  end

  test "an inactive or missing store is not public" do
    get api_v1_store_path("suspended-shop"), as: :json
    assert_response :not_found
  end
end
