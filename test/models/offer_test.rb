# frozen_string_literal: true

require "test_helper"

class OfferTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    Flipper.enable(:offers)
    ActionMailer::Base.deliveries.clear
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

  def offer!(amount_cents: 60_000, **attrs)
    Offer.create!({
      listing: @listing,
      buyer: @buyer,
      conversation: @conversation,
      offerer: @buyer,
      amount_cents: amount_cents
    }.merge(attrs))
  end

  test "validates the amount against the listing price" do
    too_low = Offer.new(listing: @listing, buyer: @buyer, conversation: @conversation,
                        offerer: @buyer, amount_cents: 10_000)
    assert_not too_low.valid?
    assert too_low.errors[:amount_cents].any?

    too_high = Offer.new(listing: @listing, buyer: @buyer, conversation: @conversation,
                         offerer: @buyer, amount_cents: @listing.price_cents)
    assert_not too_high.valid?
  end

  test "allows only one pending buyer offer per listing" do
    offer!
    duplicate = Offer.new(listing: @listing, buyer: @buyer, conversation: @conversation,
                          offerer: @buyer, amount_cents: 61_000)

    assert_not duplicate.valid?
    assert duplicate.errors[:base].any?
  end

  test "sets a 48 hour expiry" do
    offer = offer!

    assert_in_delta 48.hours.from_now.to_i, offer.expires_at.to_i, 5
  end

  test "the seller can accept an offer and both parties are notified" do
    offer = offer!

    result = Offers::Respond.new(offer: offer, actor: @seller, decision: "accept").call

    assert result.success?
    assert offer.reload.accepted?
    assert @conversation.messages.event.last.body == "offers.system.accepted"
    assert Notification.where(recipient: @buyer, kind: "offer_accepted").exists?
    assert_enqueued_emails 1
  end

  test "the seller can decline an offer" do
    offer = offer!

    result = Offers::Respond.new(offer: offer, actor: @seller, decision: "decline").call

    assert result.success?
    assert offer.reload.declined?
    assert @conversation.messages.event.last.body == "offers.system.declined"
    assert Notification.where(recipient: @buyer, kind: "offer_declined").exists?
  end

  test "the seller can counter and the buyer can accept the counter" do
    offer = offer!

    result = Offers::Respond.new(offer: offer, actor: @seller, decision: "counter",
                                 amount_cents: 70_000, message: "Meet me at 700").call

    assert result.success?
    counter = result.offer
    assert offer.reload.countered?
    assert counter.pending?
    assert_equal @seller.id, counter.offerer_id
    assert_equal @buyer.id, counter.buyer_id
    assert_equal offer.id, counter.counter_offer_id
    assert_equal "offers.system.countered", @conversation.messages.event.last.body

    accepted = Offers::Respond.new(offer: counter, actor: @buyer, decision: "accept").call

    assert accepted.success?
    assert counter.reload.accepted?
    assert counter.redeemable_by?(@buyer, listing: @listing)
    assert_not counter.redeemable_by?(@seller, listing: @listing)
  end

  test "only the recipient can respond and only while pending" do
    offer = offer!

    denied = Offers::Respond.new(offer: offer, actor: @buyer, decision: "accept").call
    assert_not denied.success?

    offer.update!(status: "declined")
    expired = Offers::Respond.new(offer: offer, actor: @seller, decision: "accept").call
    assert_not expired.success?
  end

  test "expiry marks the offer and posts an event" do
    offer = offer!
    offer.update_columns(expires_at: 1.minute.ago)

    assert Offers::Expire.new(offer: offer).call

    assert offer.reload.expired?
    assert_equal "offers.system.expired", @conversation.messages.event.last.body
    assert Notification.where(kind: "offer_expired").exists?
  end

  test "expiry is idempotent" do
    offer = offer!
    offer.update_columns(expires_at: 1.minute.ago)
    Offers::Expire.new(offer: offer).call
    clear_enqueued_jobs

    assert_not Offers::Expire.new(offer: offer).call
    assert_no_enqueued_emails
  end

  test "the expiry job expires due offers and reminds about soon-to-expire ones" do
    due = offer!
    due.update_columns(expires_at: 1.minute.ago)
    soon_listing = create_listing!(store: @listing.store, seller: @seller,
                                   title: "Soon offer listing", price_cents: 100_000)
    soon_conversation = Conversation.create!(listing: soon_listing, buyer: @buyer,
                                             seller: @seller, store: @listing.store)
    soon = Offer.create!(listing: soon_listing, buyer: @buyer, conversation: soon_conversation,
                         offerer: @buyer, amount_cents: 50_000)
    soon.update_columns(expires_at: 2.hours.from_now)

    Offers::ExpiryJob.perform_now

    assert due.reload.expired?
    assert soon.reload.expiry_reminder_sent_at.present?
    assert Notification.where(recipient: @seller, kind: "offer_expiring").exists? ||
           Notification.where(recipient: @buyer, kind: "offer_expiring").exists?
  end
end
