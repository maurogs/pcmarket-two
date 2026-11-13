# frozen_string_literal: true

require "test_helper"

class MessageTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @listing = listings(:published_gpu)
    @buyer = users(:seller_two)
    @seller = @listing.seller
    @conversation = Conversation.create!(
      listing: @listing, buyer: @buyer, seller: @seller, store: @listing.store
    )
    clear_enqueued_jobs
  end

  test "creates a text message and flags safety patterns" do
    message = @conversation.messages.create!(
      sender: @buyer,
      body: "Write me at buyer@example.com or call 600 123 456"
    )

    assert message.persisted?
    assert message.safety_flagged?
    assert_includes message.safety_reasons, "email"
    assert_includes message.safety_reasons, "phone"
  end

  test "does not flag ordinary prices" do
    message = @conversation.messages.create!(sender: @buyer, body: "Can you do 450 €?")

    assert_not message.safety_flagged?
    assert_empty message.safety_reasons
  end

  test "requires a body between 1 and 2000 characters" do
    message = @conversation.messages.new(sender: @buyer, body: "")

    assert_not message.valid?
    assert message.errors[:body].any?

    message.body = "x" * 2001
    assert_not message.valid?
  end

  test "rejects senders outside the conversation" do
    message = @conversation.messages.new(sender: users(:moderator), body: "Hello")

    assert_not message.valid?
    assert message.errors[:sender_id].any?
  end

  test "rejects messages between blocked users" do
    Block.create!(blocker: @seller, blocked: @buyer)
    message = @conversation.messages.new(sender: @buyer, body: "Hello")

    assert_not message.valid?
    assert message.errors[:base].any?
  end

  test "rate limits text messages per sender" do
    30.times { |index| @conversation.messages.create!(sender: @buyer, body: "Message #{index}") }

    message = @conversation.messages.new(sender: @buyer, body: "One too many")

    assert_not message.valid?
    assert_includes message.errors.full_messages.join, "30"
  end

  test "limits message attachments to four images" do
    message = @conversation.messages.new(sender: @buyer, body: "Photos")
    5.times do |index|
      message.images.attach(
        io: File.open(file_fixture("listing.png")),
        filename: "photo-#{index}.png",
        content_type: "image/png"
      )
    end

    assert_not message.valid?
    assert message.errors[:images].any?
  end

  test "system events store a translation key instead of literal text" do
    message = Message.event!(
      conversation: @conversation,
      sender: @buyer,
      key: "offers.system.created",
      metadata: { amount_cents: 10_000, currency: "EUR" }
    )

    assert message.system?
    assert_equal "offers.system.created", message.body
    assert_equal 10_000, message.metadata["amount_cents"]
  end

  test "enqueues a Turbo broadcast and a delayed email notification" do
    assert_enqueued_with(job: Turbo::Streams::ActionBroadcastJob) do
      assert_enqueued_with(job: Messages::EmailNotificationJob) do
        @conversation.messages.create!(sender: @buyer, body: "Hello there")
      end
    end
  end

  test "records an in-app new_message notification for the recipient" do
    assert_difference -> { Notification.where(recipient: @seller, kind: "new_message").count }, 1 do
      @conversation.messages.create!(sender: @buyer, body: "Hello there")
    end
  end

  test "system messages do not create message notifications" do
    assert_no_difference -> { Notification.where(kind: "new_message").count } do
      Message.event!(conversation: @conversation, sender: @buyer, key: "offers.system.expired")
    end
  end
end
