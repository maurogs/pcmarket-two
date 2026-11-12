# frozen_string_literal: true

require "test_helper"

class SavedSearches::MatcherTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    @other_region = Region.create!(country_code: "ES", name: "Barcelona", code: "B", position: 2)
    clear_enqueued_jobs
  end

  def search_for(**attrs)
    SavedSearch.create!({
      user: @user,
      name: "Watch",
      query_params: {},
      frequency: "daily"
    }.merge(attrs))
  end

  def listing_in(category, **attrs)
    create_listing!(**{ store: @store, seller: @seller, category: category }.merge(attrs))
  end

  def matched?(search, listing)
    SavedSearches::Matcher.new(listing).call
    Notification.exists?(kind: "saved_search_match", notifiable: listing, recipient: @user)
  end

  test "matches a child category through the subtree and rejects a sibling category" do
    search = search_for(category: categories(:gpus))
    child = listing_in(categories(:nvidia), title: "Child NVIDIA GPU", specs: { gpu_chipset: "nvidia" })
    sibling = listing_in(categories(:cpus), title: "Sibling CPU")

    assert matched?(search, child)
    assert_not matched?(search, sibling)
  end

  test "enforces the maximum price and rejects listings above it" do
    search = search_for(query_params: { "max_price" => "100" })
    match = listing_in(categories(:cpus), title: "Cheap CPU", price_cents: 5_000)
    expensive = listing_in(categories(:cpus), title: "Expensive CPU", price_cents: 15_000)

    assert matched?(search, match)
    assert_not matched?(search, expensive)
  end

  test "enforces the minimum price and rejects listings below it" do
    search = search_for(query_params: { "min_price" => "100" })
    match = listing_in(categories(:cpus), title: "Premium CPU", price_cents: 15_000)
    cheap = listing_in(categories(:cpus), title: "Budget CPU", price_cents: 5_000)

    assert matched?(search, match)
    assert_not matched?(search, cheap)
  end

  test "enforces the condition" do
    search = search_for(query_params: { "condition" => [ "used_good" ] })
    match = listing_in(categories(:cpus), title: "Used good CPU", condition: :used_good)
    wrong = listing_in(categories(:cpus), title: "Used like new CPU", condition: :used_like_new)

    assert matched?(search, match)
    assert_not matched?(search, wrong)
  end

  test "enforces the specs" do
    search = search_for(category: categories(:gpus),
                        query_params: { "specs" => { "gpu_chipset" => [ "nvidia" ] } })
    match = listing_in(categories(:gpus), title: "NVIDIA card", specs: { gpu_chipset: "nvidia" })
    wrong = listing_in(categories(:gpus), title: "AMD card", specs: { gpu_chipset: "amd" })

    assert matched?(search, match)
    assert_not matched?(search, wrong)
  end

  test "enforces the tags" do
    search = search_for(query_params: { "tags" => [ "featured" ] })
    match = listing_in(categories(:cpus), title: "Featured CPU", tags: [ tags(:featured) ])
    wrong = listing_in(categories(:cpus), title: "Plain CPU")

    assert matched?(search, match)
    assert_not matched?(search, wrong)
  end

  test "enforces the region" do
    search = search_for(query_params: { "region" => regions(:madrid).id.to_s })
    match = listing_in(categories(:cpus), title: "Madrid CPU", region: regions(:madrid))
    wrong = listing_in(categories(:cpus), title: "Barcelona CPU", region: @other_region)

    assert matched?(search, match)
    assert_not matched?(search, wrong)
  end

  test "enforces the full-text query" do
    search = search_for(query_params: { "q" => "Radeon" })
    match = listing_in(categories(:cpus), title: "Radeon CPU bundle")
    wrong = listing_in(categories(:cpus), title: "Intel CPU bundle")

    assert matched?(search, match)
    assert_not matched?(search, wrong)
  end

  test "enforces free shipping" do
    search = search_for(query_params: { "free_shipping" => "1" })
    match = listing_in(categories(:cpus), title: "Free shipping CPU", free_shipping: true)
    wrong = listing_in(categories(:cpus), title: "Paid shipping CPU", free_shipping: false)

    assert matched?(search, match)
    assert_not matched?(search, wrong)
  end

  test "a search without a category matches listings from every category" do
    search = search_for
    cpu = listing_in(categories(:cpus), title: "Any CPU")
    gpu = listing_in(categories(:gpus), title: "Any GPU", specs: { gpu_chipset: "nvidia" })

    assert matched?(search, cpu)
    assert matched?(search, gpu)
  end

  test "does not match listings that are not publicly visible" do
    search = search_for
    draft = listing_in(categories(:cpus), title: "Draft CPU", status: "draft")

    assert_no_difference -> { Notification.where(kind: "saved_search_match").count } do
      SavedSearches::Matcher.new(draft).call
    end
  end
end
