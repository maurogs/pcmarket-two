# frozen_string_literal: true

require "application_system_test_case"

class WishlistTest < ApplicationSystemTestCase
  test "a confirmed user favourites a listing and sees it on the wishlist" do
    user = users(:seller_two)
    listing = listings(:published_gpu)

    sign_in_as(user)
    accept_cookie_consent
    visit listing_path(id: listing.slug)

    within "#favourite_listing_#{listing.id}" do
      find("button").click
    end

    assert_selector "#favourite_listing_#{listing.id} button[aria-label='#{I18n.t("favourites.button.remove")}']"

    visit wishlist_path

    assert_text listing.title
    assert_text ApplicationController.helpers.money(listing.price_cents, currency: listing.currency)
    assert_text I18n.t("wishlist.favourites.move_to_basket")
  end
end
