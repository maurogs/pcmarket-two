# frozen_string_literal: true

class Message < ApplicationRecord
  KINDS = %w[text system offer].freeze
  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  IMAGE_MAX_SIZE = 10.megabytes
  MAX_IMAGES = 4
  MAX_PER_10_MINUTES = 30

  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: "User"

  has_many_attached :images

  enum :kind, { text: 0, system: 1, offer: 2 }, scopes: false

  validates :body, presence: true, length: { in: 1..2000 }
  validates :images,
            limit: { max: MAX_IMAGES, message: :too_many_images },
            content_type: { in: IMAGE_CONTENT_TYPES, message: :invalid_image_type },
            size: { less_than_or_equal_to: IMAGE_MAX_SIZE, message: :image_too_large }
  validate :sender_is_participant
  validate :parties_not_blocked, on: :create, if: :text?
  validate :within_message_rate_limit, on: :create, if: :text?

  before_validation :scan_safety, on: :create, if: :text?

  scope :visible, -> { where(hidden_at: nil) }
  scope :unread, -> { where(read_at: nil) }
  scope :event, -> { where(kind: %i[system offer]) }

  after_create_commit :register_on_conversation
  after_create_commit :broadcast_append
  after_create_commit :notify_recipient

  def event?
    system? || offer?
  end

  # System and offer events store a translation key in `body` plus interpolation
  # data in `metadata`, so every participant reads them in their own locale.
  def self.event!(conversation:, sender:, key:, metadata: {}, kind: :system)
    create!(
      conversation: conversation,
      sender: sender,
      kind: kind,
      body: key,
      metadata: metadata
    )
  end

  def sender_name
    sender.display_name
  end

  def safety_warning?
    safety_flagged?
  end

  private

  def sender_is_participant
    return if conversation.blank? || sender.blank?
    return if conversation.participant?(sender)

    errors.add(:sender_id, I18n.t("messages.errors.not_participant"))
  end

  def parties_not_blocked
    return if conversation.blank? || sender.blank?

    other = conversation.other_party_for(sender)
    return unless Block.between?(sender, other)

    errors.add(:base, I18n.t("messages.errors.blocked"))
  end

  def within_message_rate_limit
    return if sender_id.blank?

    count = self.class.where(sender_id: sender_id)
                      .where(kind: KINDS.index("text"))
                      .where(created_at: 10.minutes.ago..)
                      .count
    return if count < MAX_PER_10_MINUTES

    errors.add(:base, I18n.t("messages.errors.rate_limited", max: MAX_PER_10_MINUTES))
  end

  def scan_safety
    reasons = Messages::SafetyScanner.call(body)
    self.safety_reasons = reasons
    self.safety_flagged = reasons.any?
  end

  def register_on_conversation
    conversation.register_message!(self)
  end

  def broadcast_append
    Turbo::StreamsChannel.broadcast_append_later_to(
      conversation,
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
    )
  end

  def notify_recipient
    return unless text?

    recipient = conversation.other_party_for(sender)
    return if recipient.blank?

    Notifications.record(
      recipient: recipient,
      kind: "new_message",
      notifiable: self,
      params: {
        sender_name: sender.display_name,
        title: conversation.display_title,
        conversation_id: conversation_id
      }
    )

    Messages::EmailNotificationJob.set(wait: 10.minutes).perform_later(id)
  end
end
