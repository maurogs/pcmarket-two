# frozen_string_literal: true

require "test_helper"

class Messages::EmailNotificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
    @listing = listings(:published_gpu)
    @buyer = users(:seller_two)
    @seller = @listing.seller
    @conversation = Conversation.create!(
      listing: @listing, buyer: @buyer, seller: @seller, store: @listing.store
    )
  end

  test "emails the recipient when the message is still unread" do
    message = @conversation.messages.create!(sender: @buyer, body: "Hello, is this available?")

    assert_emails 1 do
      Messages::EmailNotificationJob.perform_now(message.id)
    end
    assert_equal [ @seller.email ], ActionMailer::Base.deliveries.last.to
  end

  test "does not email when the recipient has read the message" do
    message = @conversation.messages.create!(sender: @buyer, body: "Hello")
    @conversation.mark_read_for!(@seller)

    assert_no_emails do
      Messages::EmailNotificationJob.perform_now(message.id)
    end
  end

  test "respects the recipient email preference" do
    NotificationPreference.create!(user: @seller, kind: "new_message", in_app: true, email: false)
    message = @conversation.messages.create!(sender: @buyer, body: "Hello")

    assert_no_emails do
      Messages::EmailNotificationJob.perform_now(message.id)
    end
  end

  test "does not email system events" do
    message = Message.event!(conversation: @conversation, sender: @buyer,
                             key: "offers.system.created", metadata: { amount_cents: 1_000 })

    assert_no_emails do
      Messages::EmailNotificationJob.perform_now(message.id)
    end
  end
end
