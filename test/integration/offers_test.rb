# frozen_string_literal: true

require "test_helper"

class OffersTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    Flipper.enable(:offers)
    clear_enqueued_jobs
    @listing = listings(:published_gpu)
    @buyer = users(:seller_two)
    @seller = @listing.seller
    @conversation = Conversation.create!(
      listing: @listing, buyer: @buyer, seller: @seller, store: @listing.store
    )
  end

  teardown do
    Flipper.disable(:offers)
  end

  def offer!(amount_cents: 60_000, status: "pending", **attrs)
    offer = Offer.create!({
      listing: @listing,
      buyer: @buyer,
      conversation: @conversation,
      offerer: @buyer,
      amount_cents: amount_cents
    }.merge(attrs))
    offer.update!(status: status) unless status == "pending"
    offer
  end

  test "offer endpoints return 404 when the flag is off" do
    Flipper.disable(:offers)
    offer = offer!

    post listing_offers_path(@listing, locale: :en), params: { amount: "600" }
    assert_response :not_found

    patch offer_path(offer, locale: :en), params: { decision: "accept" }
    assert_response :not_found
  end

  test "a buyer creates an offer and the conversation gets an offer event" do
    sign_in @buyer

    assert_difference -> { Offer.count }, 1 do
      assert_difference -> { @conversation.messages.event.count }, 1 do
        post listing_offers_path(@listing, locale: :en),
             params: { amount: "600", message: "Would you accept 600?" }
      end
    end

    offer = Offer.last
    assert_redirected_to conversation_path(offer.conversation, locale: :en)
    assert_nil flash[:alert]
    assert_equal 60_000, offer.amount_cents
    assert_equal @buyer, offer.offerer
    assert_equal "offers.system.created", @conversation.messages.event.last.body
  end

  test "offers below half the price are rejected" do
    sign_in @buyer

    assert_no_difference -> { Offer.count } do
      post listing_offers_path(@listing, locale: :en), params: { amount: "100" }
    end

    assert_redirected_to listing_path(@listing, locale: :en)
  end

  test "the seller accepts an offer and the buyer can buy at that price" do
    offer = offer!
    sign_in @seller

    patch offer_path(offer, locale: :en), params: { decision: "accept" }

    assert_redirected_to conversation_path(@conversation, locale: :en)
    assert offer.reload.accepted?

    sign_out @seller
    sign_in @buyer

    post cart_items_path(locale: :en),
         params: { listing_id: @listing.id, offer_id: offer.id, quantity: 1, buy_now: true }
    assert_redirected_to new_checkout_path(locale: :en, buy_now: @listing.id)

    post checkout_path(locale: :en), params: {
      email: @buyer.email,
      terms_accepted: "1",
      idempotency_key: SecureRandom.uuid,
      buy_now_listing_id: @listing.id,
      address: default_address_attributes,
      fulfilment: { @listing.store_id.to_s => "shipping" }
    }

    assert_redirected_to checkout_path(locale: :en)
    order = Checkout.find_by!(buyer: @buyer).orders.first
    assert_equal 60_000, order.items.first.unit_price_cents
    assert_equal 60_000, order.subtotal_cents
  end

  test "the seller can decline and counter an offer" do
    offer = offer!
    sign_in @seller

    patch offer_path(offer, locale: :en), params: { decision: "decline" }
    assert offer.reload.declined?

    second = offer!(amount_cents: 61_000)
    patch offer_path(second, locale: :en),
          params: { decision: "counter", amount: "700", message: "Best I can do" }

    assert_redirected_to conversation_path(@conversation, locale: :en)
    counter = Offer.pending.last
    assert_equal 70_000, counter.amount_cents
    assert_equal @seller.id, counter.offerer_id
    assert_equal second.id, counter.counter_offer_id
    assert second.reload.countered?
  end

  test "a buyer cannot accept their own offer" do
    offer = offer!
    sign_in @buyer

    patch offer_path(offer, locale: :en), params: { decision: "accept" }

    assert offer.reload.pending?
    assert_equal I18n.t("offers.errors.not_recipient", locale: :en), flash[:alert]
  end
end
