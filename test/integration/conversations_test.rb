# frozen_string_literal: true

require "test_helper"

class ConversationsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @listing = listings(:published_gpu)
    @buyer = users(:seller_two)
    @seller = @listing.seller
    clear_enqueued_jobs
  end

  def conversation!
    Conversation.create!(listing: @listing, buyer: @buyer, seller: @seller, store: @listing.store)
  end

  test "a buyer opens a conversation from a listing" do
    sign_in @buyer

    assert_difference -> { Conversation.count }, 1 do
      post conversations_path(locale: :en), params: { listing_id: @listing.id }
    end

    conversation = Conversation.last
    assert_redirected_to conversation_path(conversation, locale: :en)
    assert_equal I18n.t("conversations.flash.opened", locale: :en), flash[:notice]
    assert_equal @buyer, conversation.buyer
    assert_equal @seller, conversation.seller
  end

  test "reopening the same listing conversation does not duplicate it" do
    sign_in @buyer
    post conversations_path(locale: :en), params: { listing_id: @listing.id }

    assert_no_difference -> { Conversation.count } do
      post conversations_path(locale: :en), params: { listing_id: @listing.id }
    end
  end

  test "users cannot message themselves" do
    sign_in @seller

    assert_no_difference -> { Conversation.count } do
      post conversations_path(locale: :en), params: { listing_id: @listing.id }
    end

    assert_equal I18n.t("conversations.errors.self", locale: :en), flash[:alert]
  end

  test "blocked users cannot start a conversation" do
    Block.create!(blocker: @seller, blocked: @buyer)
    sign_in @buyer

    assert_no_difference -> { Conversation.count } do
      post conversations_path(locale: :en), params: { listing_id: @listing.id }
    end

    assert_equal I18n.t("conversations.errors.blocked", locale: :en), flash[:alert]
  end

  test "the inbox lists conversations with unread badges and mark all read works" do
    conversation = conversation!
    conversation.messages.create!(sender: @buyer, body: "Is it still available?")
    sign_in @seller

    get conversations_path(locale: :en)

    assert_response :success
    assert_includes response.body, @buyer.display_name
    assert_includes response.body, "Is it still available?"

    post inbox_read_path(locale: :en)

    assert_redirected_to conversations_path(locale: :en)
    assert_equal 0, conversation.reload.seller_unread_count
    assert conversation.messages.last.reload.read_at.present?
  end

  test "opening a conversation marks incoming messages as read" do
    conversation = conversation!
    message = conversation.messages.create!(sender: @buyer, body: "Hello")
    sign_in @seller

    get conversation_path(conversation, locale: :en)

    assert_response :success
    assert message.reload.read_at.present?
    assert_equal 0, conversation.reload.seller_unread_count
  end

  test "a participant can send a message through the composer" do
    conversation = conversation!
    sign_in @buyer

    assert_difference -> { conversation.messages.count }, 1 do
      post conversation_messages_path(conversation, locale: :en),
           params: { message: { body: "Would you take 650 €?" } }
    end

    assert_redirected_to conversation_path(conversation, locale: :en)
    assert_equal @buyer, conversation.messages.last.sender
    assert_equal 1, conversation.reload.seller_unread_count
  end

  test "blocked users cannot see the conversation or send messages" do
    conversation = conversation!
    sign_in @buyer
    post blocks_path(locale: :en), params: { blocked_user_id: @seller.id }

    get conversation_path(conversation, locale: :en)
    assert_redirected_to root_path(locale: :es)

    post conversation_messages_path(conversation, locale: :en),
         params: { message: { body: "Still there?" } }
    assert_redirected_to root_path(locale: :es)
  end

  test "the blocked users tab lists blocked accounts and can unblock them" do
    block = Block.create!(blocker: @buyer, blocked: @seller)
    sign_in @buyer

    get conversations_path(tab: "blocked", locale: :en)

    assert_response :success
    assert_includes response.body, @seller.display_name
    assert_includes response.body, I18n.t("blocks.unblock", locale: :en)

    delete block_path(block, locale: :en)

    assert_redirected_to root_path(locale: :en)
    assert_not Block.exists?(block.id)
  end
end
