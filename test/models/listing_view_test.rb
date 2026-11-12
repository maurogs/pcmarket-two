# frozen_string_literal: true

require "test_helper"

class ListingViewTest < ActiveSupport::TestCase
  setup do
    @listing = listings(:published_gpu)
  end

  test "increments a daily rollup atomically with an upsert" do
    ListingView.where(listing: @listing).delete_all

    ListingView.increment_for(@listing.id, date: Date.current)
    ListingView.increment_for(@listing.id, date: Date.current)

    row = ListingView.find_by!(listing: @listing, date: Date.current)
    assert_equal 2, row.views
    assert_equal 1, ListingView.where(listing: @listing, date: Date.current).count
  end

  test "keeps separate rows for different days" do
    ListingView.where(listing: @listing).delete_all

    ListingView.increment_for(@listing.id, date: Date.current)
    ListingView.increment_for(@listing.id, date: Date.current - 1)

    assert_equal 2, ListingView.where(listing: @listing).count
  end
end
