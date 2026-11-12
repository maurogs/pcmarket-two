# frozen_string_literal: true

require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  setup do
    @listing = listings(:published_gpu)
    @buyer = users(:seller_two)
    @seller = @listing.seller
  end

  def build_conversation(**attrs)
    Conversation.new({
      listing: @listing,
      buyer: @buyer,
      seller: @seller,
      store: @listing.store
    }.merge(attrs))
  end

  test "requires two different parties" do
    conversation = build_conversation(buyer: @seller)

    assert_not conversation.valid?
    assert conversation.errors[:buyer_id].any?
  end

  test "is unique per listing and buyer" do
    build_conversation.save!

    duplicate = build_conversation
    assert_not duplicate.valid?
    assert duplicate.errors[:buyer_id].any?
  end

  test "is unique per store when it has no listing" do
    Conversation.create!(buyer: @buyer, seller: @seller, store: @listing.store)

    duplicate = Conversation.new(buyer: @buyer, seller: @seller, store: @listing.store)
    assert_not duplicate.valid?
  end

  test "blocked parties cannot start a conversation" do
    Block.create!(blocker: @buyer, blocked: @seller)

    conversation = build_conversation
    assert_not conversation.valid?
    assert conversation.errors[:base].any?
  end

  test "rejects a listing that does not belong to the store" do
    other_store = stores(:suspended_store)
    conversation = build_conversation(store: other_store)

    assert_not conversation.valid?
    assert conversation.errors[:seller_id].any? || conversation.errors[:listing_id].any?
  end

  test "limits new conversations per buyer per hour" do
    10.times do |index|
      listing = create_listing!(store: @listing.store, seller: @seller, title: "Rate listing #{index}")
      Conversation.create!(listing: listing, buyer: @buyer, seller: @seller, store: @listing.store)
    end

    extra = create_listing!(store: @listing.store, seller: @seller, title: "One more rate listing")
    conversation = Conversation.new(listing: extra, buyer: @buyer, seller: @seller, store: @listing.store)

    assert_not conversation.valid?
    assert_includes conversation.errors.full_messages.join, "10"
  end

  test "tracks unread counters and last message time per side" do
    conversation = build_conversation
    conversation.save!

    message = conversation.messages.create!(sender: @buyer, body: "Is this still available?")

    conversation.reload
    assert_equal 0, conversation.buyer_unread_count
    assert_equal 1, conversation.seller_unread_count
    assert_equal message.created_at.to_i, conversation.last_message_at.to_i
    assert_equal 1, conversation.unread_count_for(@seller)

    conversation.mark_read_for!(@seller)

    assert_equal 0, conversation.reload.seller_unread_count
    assert message.reload.read_at.present?
  end
end
