# frozen_string_literal: true

require "application_system_test_case"

class SellAndModerateTest < ApplicationSystemTestCase
  test "a seller submits a listing and an admin approves it" do
    title = "NVIDIA RTX 5090 Smoke Test"

    sign_in_as(users(:confirmed))
    accept_cookie_consent
    visit new_sell_listing_path

    # Category step: reveal the Components children and pick Graphics Cards.
    find("button[data-category-picker-root-param='#{categories(:components).id}']").click
    choose "category_#{categories(:gpus).id}"
    click_button I18n.t("sell.steps.continue")

    # Photos step: Active Storage uploads the fixture through a direct upload.
    assert_text I18n.t("sell.photos.title")
    attach_file "listing[images][]", Rails.root.join("test/fixtures/files/listing.png"), make_visible: true
    click_button I18n.t("sell.steps.continue")

    # Details step.
    assert_text I18n.t("sell.details.title")
    fill_in "listing_title", with: title
    choose "listing_condition_used_like_new"
    fill_in "listing_description", with: "A powerful graphics card in excellent condition, fully tested."
    select "NVIDIA", from: "spec_gpu_chipset"
    click_button I18n.t("sell.steps.continue")

    # Price and delivery step.
    assert_text I18n.t("sell.price.title")
    fill_in "listing_price", with: "799.00"
    fill_in "listing_shipping_price", with: "0"
    select regions(:madrid).name, from: "listing_region_id"
    fill_in "listing_city", with: "Madrid"
    fill_in "listing_postal_code", with: "28001"
    click_button I18n.t("sell.steps.continue")

    # Review step: everything is complete and the listing waits for moderation.
    assert_text I18n.t("sell.review.checklist_ok")
    click_button I18n.t("sell.steps.submit")

    assert_text I18n.t("listings.show.status_banner", status: I18n.t("listings.statuses.pending_review"))

    listing = Listing.find_by!(title: title)
    assert listing.pending_review?

    # A different user (the admin) signs in and approves it from the queue.
    reset_browser_session
    sign_in_as(users(:admin))
    accept_cookie_consent
    visit admin_listing_reviews_path

    assert_text title
    click_link title
    click_button I18n.t("admin.moderation.show.approve")

    assert_text I18n.t("admin.moderation.notices.approved")
    assert listing.reload.published?

    # Signed out, the listing is now publicly visible without a status banner.
    reset_browser_session
    visit listing_path(id: listing.slug)

    assert_text title
    assert_text ApplicationController.helpers.money(listing.price_cents, currency: listing.currency)
    assert_no_text I18n.t("listings.show.status_banner", status: I18n.t("listings.statuses.pending_review"))
  end
end
