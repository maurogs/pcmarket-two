# frozen_string_literal: true

require "test_helper"

class FavouritesTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = users(:moderator)
    @listing = create_listing!(store: stores(:confirmed_store), seller: users(:confirmed),
                               title: "Favourite integration listing")
  end

  test "a signed-in user toggles a favourite over HTML" do
    sign_in @buyer

    assert_difference -> { Favourite.count }, 1 do
      post listing_favourite_path(@listing, locale: :en),
           headers: { "Referer" => listing_path(@listing, locale: :en) }
    end

    assert_redirected_to listing_path(@listing, locale: :en)
    assert_equal I18n.t("favourites.flash.added", locale: :en), flash[:notice]

    assert_difference -> { Favourite.count }, -1 do
      delete listing_favourite_path(@listing, locale: :en),
             headers: { "Referer" => listing_path(@listing, locale: :en) }
    end

    assert_redirected_to listing_path(@listing, locale: :en)
    assert_equal I18n.t("favourites.flash.removed", locale: :en), flash[:notice]
  end

  test "destroying a missing favourite is idempotent" do
    sign_in @buyer

    assert_no_difference -> { Favourite.count } do
      delete listing_favourite_path(@listing, locale: :en),
             headers: { "Referer" => listing_path(@listing, locale: :en) }
    end

    assert_redirected_to listing_path(@listing, locale: :en)
    assert_equal I18n.t("favourites.flash.removed", locale: :en), flash[:notice]
  end

  test "the Turbo Stream response replaces the favourite button" do
    sign_in @buyer

    post listing_favourite_path(@listing, locale: :en),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, %(target="favourite_listing_#{@listing.id}")
    assert_includes response.body, %(action="replace")
  end

  test "anonymous users are sent to sign in and returned to the listing" do
    delete listing_favourite_path(@listing, locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)

    post listing_favourite_path(@listing, locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)

    post user_session_path(locale: :en),
         params: { user: { email: @buyer.email, password: "Password123!" } }

    assert_redirected_to listing_path(@listing, locale: :en)
  end

  test "the listing heart reflects the favourite state" do
    Favourite.create!(user: @buyer, listing: @listing)
    sign_in @buyer

    get listing_path(@listing, locale: :en)

    assert_response :success
    assert_select "button[aria-label=?]", I18n.t("favourites.button.remove", locale: :en)
  end
end
