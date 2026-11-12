# frozen_string_literal: true

require "test_helper"

class ListingSearchTest < ActiveSupport::TestCase
  setup do
    @category = categories(:gpus)
  end

  test "restricts results to visible listings" do
    titles = search({}, category: @category).listings.map(&:title)

    assert_includes titles, "NVIDIA GeForce RTX 4070 Ti Super"
    assert_includes titles, "AMD Radeon RX 7800 XT"
    assert_includes titles, "NVIDIA GeForce RTX 4060 Budget"
    assert_not_includes titles, "Pending Review GPU"
    assert_not_includes titles, "Draft GPU Listing"
  end

  test "excludes listings from suspended stores and banned sellers" do
    titles = search({}).listings.map(&:title)

    assert_not_includes titles, "Suspended Store Component"
    assert_not_includes titles, "Banned Seller Component"
  end

  test "filters by full text query" do
    result = search({ "q" => "Radeon" })

    assert_includes result.listings.map(&:title), "AMD Radeon RX 7800 XT"
    assert_includes result.listings.map(&:title), "Tarjeta Gráfica Radeon Usada"
    assert_not_includes result.listings.map(&:title), "NVIDIA GeForce RTX 4060 Budget"
  end

  test "filters by category scope and category slug" do
    scoped = search({}, category: @category)
    by_slug = search({ "category" => "graphics-cards" })

    assert_equal 3, scoped.total_count
    assert_equal scoped.total_count, by_slug.total_count
    assert_equal @category, by_slug.category
  end

  test "ignores an unknown category slug" do
    result = search({ "category" => "does-not-exist" }, category: @category)

    assert_equal @category, result.category
  end

  test "filters by euro price range" do
    min = search({ "min_price" => "600" }, category: @category)
    max = search({ "max_price" => "300" }, category: @category)

    assert_equal [ "NVIDIA GeForce RTX 4070 Ti Super" ], min.listings.map(&:title)
    assert_equal [ "NVIDIA GeForce RTX 4060 Budget" ], max.listings.map(&:title)
  end

  test "ignores invalid price values instead of raising" do
    result = search({ "min_price" => "abc", "max_price" => "-10" }, category: @category)

    assert_equal 3, result.total_count
    assert_nil result.min_price
    assert_nil result.max_price
  end

  test "filters by condition and ignores unknown conditions" do
    result = search({ "condition" => [ "used_good", "bogus" ] }, category: @category)

    assert_equal [ "AMD Radeon RX 7800 XT" ], result.listings.map(&:title)
  end

  test "filters by allowed specs and ignores unknown spec keys" do
    chipset = search({ "specs" => { "gpu_chipset" => [ "nvidia" ] } }, category: @category)
    unknown = search({ "specs" => { "cpu_brand" => [ "amd" ], "not_a_key" => [ "x" ] } }, category: @category)

    assert_equal 2, chipset.total_count
    assert_equal 3, unknown.total_count
  end

  test "supports scalar and array spec values" do
    memory = search({ "specs" => { "gpu_memory_type" => [ "gddr6" ] } }, category: @category)

    assert_equal %w[AMD\ Radeon\ RX\ 7800\ XT NVIDIA\ GeForce\ RTX\ 4060\ Budget].sort,
                 memory.listings.map(&:title).sort
  end

  test "ignores all spec filters when there is no category" do
    result = search({ "specs" => { "gpu_chipset" => [ "nvidia" ] } })

    assert_operator result.total_count, :>, 3
  end

  test "filters by tag slugs" do
    ListingTag.create!(listing: listings(:published_gpu), tag: tags(:featured))
    result = search({ "tags" => [ "featured" ] })

    assert_equal [ "NVIDIA GeForce RTX 4070 Ti Super" ], result.listings.map(&:title)
  end

  test "filters by region and ignores unknown region ids" do
    Listing.where(id: listings(:amd_gpu).id).update_all(region_id: regions(:ile_de_france).id)

    spain = search({ "region" => regions(:madrid).id.to_s })
    unknown = search({ "region" => "999999" })

    assert_includes spain.listings.map(&:title), "NVIDIA GeForce RTX 4070 Ti Super"
    assert_not_includes spain.listings.map(&:title), "AMD Radeon RX 7800 XT"
    assert_operator unknown.total_count, :>, 0
  end

  test "filters free shipping" do
    result = search({ "free_shipping" => "1" }, category: @category)

    assert_equal [ "NVIDIA GeForce RTX 4070 Ti Super" ], result.listings.map(&:title)
  end

  test "sorts by price and newest" do
    ascending = search({ "sort" => "price_asc" }, category: @category).listings.map(&:title)
    descending = search({ "sort" => "price_desc" }, category: @category).listings.map(&:title)
    newest = search({}, category: @category).listings.map(&:title)
    popular = search({ "sort" => "popular" }, category: @category).listings.map(&:title)

    assert_equal "NVIDIA GeForce RTX 4060 Budget", ascending.first
    assert_equal "NVIDIA GeForce RTX 4070 Ti Super", descending.first
    assert_equal "AMD Radeon RX 7800 XT", newest.first
    assert_equal "NVIDIA GeForce RTX 4070 Ti Super", popular.first
  end

  test "best match uses relevance when a query is present" do
    result = search({ "q" => "Radeon", "sort" => "best_match" })

    assert_includes result.listings.map(&:title), "AMD Radeon RX 7800 XT"
    assert_equal "best_match", result.sort
  end

  test "calculates facet counts for attribute options and conditions" do
    result = search({}, category: @category)

    assert_equal 2, result.facets[:attributes]["gpu_chipset"]["nvidia"]
    assert_equal 1, result.facets[:attributes]["gpu_chipset"]["amd"]
    assert_equal 2, result.facets[:attributes]["gpu_memory_type"]["gddr6"]
    assert_equal 1, result.facets[:attributes]["gpu_memory_type"]["gddr6x"]
    assert_equal 1, result.facets[:conditions]["used_good"]
    assert_equal 1, result.facets[:conditions]["used_like_new"]
    assert_equal 0, result.facets[:conditions]["new_sealed"]
  end

  test "facet counts honour the active spec filter" do
    result = search({ "specs" => { "gpu_chipset" => [ "amd" ] } }, category: @category)

    assert_equal 1, result.facets[:attributes]["gpu_chipset"]["amd"]
    assert_equal 0, result.facets[:attributes]["gpu_chipset"]["nvidia"]
    assert_equal 1, result.facets[:attributes]["gpu_memory_type"]["gddr6"]
    assert_equal 0, result.facets[:attributes]["gpu_memory_type"]["gddr6x"]
  end

  test "facet cache keys are scoped to the category" do
    with_cache(ActiveSupport::Cache::MemoryStore.new) do
      gpus = search({}, category: @category)
      cpus = search({}, category: categories(:cpus))

      assert_equal 2, gpus.facets[:attributes]["gpu_chipset"]["nvidia"]
      assert_not cpus.facets[:attributes].key?("gpu_chipset")
    end
  end

  test "paginates results" do
    now = Time.current
    rows = 30.times.map do |index|
      {
        store_id: stores(:confirmed_store).id,
        user_id: users(:confirmed).id,
        category_id: @category.id,
        title: "Bulk GPU #{index}",
        description: "A bulk-created listing used only by the pagination test.",
        slug: "bulk-gpu-#{index}",
        condition: Listing.conditions[:used_good],
        price_cents: 10_000 + index,
        currency: "EUR",
        quantity: 1,
        specs: {},
        status: "published",
        published_at: now - index.minutes,
        country_code: "ES",
        region_id: regions(:madrid).id,
        shipping_mode: Listing.shipping_modes[:shipping],
        shipping_price_cents: 0,
        free_shipping: false,
        handling_days: 3,
        allow_offers: true,
        views_count: 0,
        favorites_count: 0,
        created_at: now,
        updated_at: now
      }
    end
    Listing.insert_all!(rows)

    first_page = search({}, category: @category)
    second_page = search({ "page" => "2" }, category: @category)

    assert_equal 33, first_page.total_count
    assert_equal 24, first_page.listings.size
    assert_equal 9, second_page.listings.size
    assert_equal 2, first_page.pagy.pages
  end

  test "never raises on malformed params" do
    result = search(
      {
        "min_price" => "abc",
        "max_price" => [],
        "condition" => [ "bogus" ],
        "region" => "xx",
        "page" => "nope",
        "specs" => "oops",
        "tags" => "nope",
        "sort" => "explode"
      },
      category: @category
    )

    assert_equal 3, result.total_count
    assert_equal "best_match", result.sort
  end

  test "builds applied filters with removable params" do
    result = search(
      { "condition" => [ "used_good" ], "min_price" => "100", "sort" => "price_asc" },
      category: @category
    )

    labels = result.applied_filters.map { |filter| filter[:label] }
    assert_includes labels, I18n.t("listings.conditions.used_good")
    assert_equal 2, result.active_filter_count
    assert_equal "price_asc", result.applied_filters.last[:remove_params]["sort"]
  end

  private

  def search(params, category: nil)
    ListingSearch.new(params, category: category).call
  end
end
