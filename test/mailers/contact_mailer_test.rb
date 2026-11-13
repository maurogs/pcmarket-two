# frozen_string_literal: true

require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  test "sends the message to the configured support address" do
    Setting.set(:support_email, "help@pcmarket.example")
    message = ContactMessage.create!(
      name: "Marta López",
      email: "marta@example.com",
      topic: "shipping",
      message: "The parcel has been stuck in transit for a week."
    )

    email = ContactMailer.notification(message)

    assert_equal [ "help@pcmarket.example" ], email.to
    assert_equal [ "marta@example.com" ], email.reply_to
    assert_includes email.subject, I18n.t("contact.topics.shipping")
    assert_includes email.body.encoded, "The parcel has been stuck"
  ensure
    Setting.set(:support_email, "support@pcmarket.example")
  end
end
