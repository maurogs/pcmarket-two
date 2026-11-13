# frozen_string_literal: true

require "test_helper"

class MessageMailerTest < ActionMailer::TestCase
  setup do
    @listing = listings(:published_gpu)
    @buyer = users(:seller_two)
    @seller = @listing.seller
    @conversation = Conversation.create!(
      listing: @listing, buyer: @buyer, seller: @seller, store: @listing.store
    )
  end

  test "new message renders in the recipient locale" do
    @seller.update!(locale: "en")
    message = @conversation.messages.create!(sender: @buyer, body: "Is it still available?")

    mail = MessageMailer.new_message(message)

    assert_equal [ @seller.email ], mail.to
    assert_equal I18n.t("message_mailer.new_message.subject", sender: @buyer.display_name, locale: :en),
                 mail.subject
    assert_includes mail.body.encoded, "Is it still available?"
  end
end
