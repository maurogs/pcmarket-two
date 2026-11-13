# frozen_string_literal: true

require "test_helper"

class ApiV1MessagingTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = users(:moderator)
    @seller = users(:confirmed)
    @listing = listings(:published_gpu)
    @buyer_token = issue_api_session(@buyer).at(1)
    @seller_token = issue_api_session(@seller).at(1)
    @headers = api_headers(@buyer_token)
    Flipper.enable(:offers)
  end

  teardown do
    Flipper.disable(:offers)
  end

  test "conversations can be created, listed and shown" do
    post api_v1_conversations_path, headers: @headers,
         params: { listing_id: @listing.id }, as: :json
    assert_response :created
    conversation_id = json_data["id"]
    assert_equal @listing.id, json_data["listing_id"]

    get api_v1_conversations_path, headers: @headers, as: :json
    assert_response :success
    assert_equal [ conversation_id ], json_data.map { |conversation| conversation["id"] }

    get api_v1_conversation_path(conversation_id), headers: @headers, as: :json
    assert_response :success
    assert_equal conversation_id, json_data.dig("conversation", "id")
    assert json_data["messages"].is_a?(Array)
  end

  test "a user cannot read another user's conversation" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer,
                                        seller: @seller, store: @listing.store)

    get api_v1_conversation_path(conversation),
        headers: api_headers(issue_api_session(users(:seller_two)).at(1)), as: :json

    assert_response :not_found
  end

  test "messages use cursor pagination and mark read" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer,
                                        seller: @seller, store: @listing.store)
    first = conversation.messages.create!(sender: @seller, body: "First message")
    second = conversation.messages.create!(sender: @buyer, body: "Second message")
    third = conversation.messages.create!(sender: @seller, body: "Third message")

    get api_v1_conversation_messages_path(conversation), headers: @headers,
        params: { per_page: 2 }, as: :json
    assert_response :success
    assert_equal [ second.id, third.id ], json_data.map { |message| message["id"] }
    assert json_meta["has_more"]
    assert_equal second.id, json_meta["next_before_id"]

    get api_v1_conversation_messages_path(conversation), headers: @headers,
        params: { per_page: 2, before_id: json_meta["next_before_id"] }, as: :json
    assert_response :success
    assert_equal [ first.id ], json_data.map { |message| message["id"] }
    assert_not json_meta["has_more"]
  end

  test "creates a message and can attach an image by signed id" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer,
                                        seller: @seller, store: @listing.store)
    data = "image-bytes"
    post api_v1_direct_uploads_path, headers: @headers, params: {
      blob: {
        filename: "message.png", byte_size: data.bytesize,
        checksum: Digest::MD5.base64digest(data), content_type: "image/png",
        metadata: {}
      }
    }, as: :json
    assert_response :created
    signed_id = json_data["signed_id"]
    ActiveStorage::Blob.find_signed!(signed_id).upload(StringIO.new(data))

    post api_v1_conversation_messages_path(conversation), headers: @headers,
         params: {
           message: { body: "Is this still available?", image_signed_ids: [ signed_id ] }
         }, as: :json

    assert_response :created
    assert_equal "Is this still available?", json_data["body"]
    assert_equal @buyer.id, json_data.dig("sender", "id")
    assert_equal 1, json_data["images"].size
  end

  test "a participant can mark the conversation as read" do
    conversation = Conversation.create!(listing: @listing, buyer: @buyer,
                                        seller: @seller, store: @listing.store)
    conversation.messages.create!(sender: @seller, body: "Hello there")

    post api_v1_conversation_read_path(conversation), headers: @headers, as: :json

    assert_response :success
    assert_equal 0, json_data["unread_count"]
  end

  test "offers can be created, countered and accepted" do
    post api_v1_offers_path, headers: @headers,
         params: { listing_id: @listing.id, amount: "700", message: "Would you take this?" },
         as: :json
    assert_response :created
    offer_id = json_data["id"]
    assert_equal 70_000, json_data["amount_cents"]

    patch api_v1_offer_path(offer_id), headers: api_headers(@seller_token),
          params: { decision: "counter", amount: "740" }, as: :json
    assert_response :success
    counter_id = json_data["id"]
    assert_equal "pending", json_data["status"]

    patch api_v1_offer_path(counter_id), headers: @headers,
          params: { decision: "accept" }, as: :json
    assert_response :success
    assert_equal "accepted", json_data["status"]
  end

  test "offers can be declined and withdrawn" do
    post api_v1_offers_path, headers: @headers,
         params: { listing_id: @listing.id, amount: "700" }, as: :json
    offer_id = json_data["id"]

    patch api_v1_offer_path(offer_id), headers: @headers,
          params: { decision: "withdraw" }, as: :json
    assert_response :success
    assert_equal "withdrawn", json_data["status"]

    post api_v1_offers_path, headers: @headers,
         params: { listing_id: @listing.id, amount: "710" }, as: :json
    declined_id = json_data["id"]

    patch api_v1_offer_path(declined_id), headers: api_headers(@seller_token),
          params: { decision: "decline" }, as: :json
    assert_response :success
    assert_equal "declined", json_data["status"]
  end

  test "the offers feature flag returns feature_disabled" do
    Flipper.disable(:offers)

    post api_v1_offers_path, headers: @headers,
         params: { listing_id: @listing.id, amount: "700" }, as: :json

    assert_response :not_found
    assert_equal "feature_disabled", json.dig("error", "code")
  end

  test "blocks can be listed, created and destroyed" do
    post api_v1_blocks_path, headers: @headers,
         params: { blocked_user_id: @seller.id }, as: :json
    assert_response :created
    block_id = json_data["id"]

    get api_v1_blocks_path, headers: @headers, as: :json
    assert_response :success
    assert_equal [ block_id ], json_data.map { |block| block["id"] }

    delete api_v1_block_path(block_id), headers: @headers, as: :json
    assert_response :no_content
  end

  test "reports can be submitted" do
    post api_v1_reports_path, headers: @headers, params: {
      reportable_type: "Listing", reportable_id: @listing.id,
      reason: "misleading",
      details: "The listing description does not match the photos."
    }, as: :json

    assert_response :created
    assert_equal "open", json_data["status"]
    assert_equal @buyer.id, Report.last.reporter_id
  end
end
