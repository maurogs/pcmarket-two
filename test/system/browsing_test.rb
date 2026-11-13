# frozen_string_literal: true

require "application_system_test_case"

class BrowsingTest < ApplicationSystemTestCase
  test "the home page loads" do
    visit root_path

    assert_text I18n.t("home.pc_finder.title")
    assert_text I18n.t("home.sell.title")
  end

  test "searching for a keyword shows the matching published listing" do
    listing = listings(:published_gpu)

    visit root_path
    fill_in "header-search", with: "RTX 4070"
    find("#header-search").send_keys(:enter)

    assert_text I18n.t("listings.index.search_title", query: "RTX 4070")
    assert_text listing.title
    assert_no_text listings(:amd_gpu).title
  end

  test "a sidebar filter narrows the results" do
    visit category_path(id: categories(:gpus).slug)

    assert_text listings(:published_gpu).title
    assert_text listings(:amd_gpu).title

    check "filters_condition_used_fair"

    assert_text listings(:nvidia_budget).title
    assert_no_text listings(:published_gpu).title
    assert_no_text listings(:amd_gpu).title
  end

  test "opening a listing shows its title and price" do
    listing = listings(:published_gpu)

    visit listing_path(id: listing.slug)

    assert_text listing.title
    assert_text ApplicationController.helpers.money(listing.price_cents, currency: listing.currency)
  end
end
