# frozen_string_literal: true

class Messages::EmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return if message.blank? || !message.text? || message.read_at.present?

    conversation = message.conversation
    recipient = conversation.other_party_for(message.sender)
    return if recipient.blank?
    return if Block.between?(message.sender, recipient)
    return unless Notifications.deliver_email?(recipient, "new_message")

    MessageMailer.new_message(message).deliver_now
  end
end
