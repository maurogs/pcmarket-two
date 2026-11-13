# frozen_string_literal: true

require "test_helper"

class OfferMailerTest < ActionMailer::TestCase
  setup do
    @listing = listings(:published_gpu)
    @buyer = users(:seller_two)
    @seller = @listing.seller
    @conversation = Conversation.create!(
      listing: @listing, buyer: @buyer, seller: @seller, store: @listing.store
    )
    @offer = Offer.create!(
      listing: @listing, buyer: @buyer, conversation: @conversation,
      offerer: @buyer, amount_cents: 60_000
    )
  end

  test "new offer emails the seller" do
    @seller.update!(locale: "en")

    mail = OfferMailer.new_offer(@offer)

    assert_equal [ @seller.email ], mail.to
    assert_equal I18n.t("offer_mailer.new_offer.subject", title: @listing.title, locale: :en),
                 mail.subject
    assert_includes mail.body.encoded, "600"
  end

  test "accepted offer emails the buyer" do
    @buyer.update!(locale: "es")
    @offer.accept!

    mail = OfferMailer.offer_accepted(@offer)

    assert_equal [ @buyer.email ], mail.to
    assert_equal I18n.t("offer_mailer.offer_accepted.subject", title: @listing.title, locale: :es),
                 mail.subject
  end

  test "counter and expiry emails render" do
    @offer.mark_countered!
    counter = Offer.create!(
      listing: @listing, buyer: @buyer, conversation: @conversation,
      offerer: @seller, counter_offer: @offer, amount_cents: 70_000
    )

    assert_equal [ @buyer.email ], OfferMailer.offer_countered(counter).to
    assert_equal [ @buyer.email ], OfferMailer.offer_expiring(counter).to
    assert_equal [ @seller.email ], OfferMailer.offer_expired(counter).to
  end
end
