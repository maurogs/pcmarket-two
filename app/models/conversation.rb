# frozen_string_literal: true

class Conversation < ApplicationRecord
  MAX_NEW_PER_HOUR = 10

  belongs_to :listing, optional: true
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"
  belongs_to :store

  has_many :messages, -> { order(:created_at, :id) }, dependent: :destroy, inverse_of: :conversation
  has_many :offers, dependent: :destroy

  validates :buyer_id, uniqueness: { scope: :listing_id }, if: -> { listing_id.present? }
  validates :buyer_id, uniqueness: { scope: :store_id }, unless: -> { listing_id.present? }
  validate :buyer_is_not_seller
  validate :store_matches_seller
  validate :listing_matches_store, if: -> { listing_id.present? }
  validate :parties_not_blocked, on: :create
  validate :within_conversation_rate_limit, on: :create

  scope :for_user, lambda { |user|
    where(buyer_id: user.id).or(where(seller_id: user.id))
  }
  scope :recent, lambda {
    order(Arel.sql("COALESCE(conversations.last_message_at, conversations.created_at) DESC"),
          id: :desc)
  }
  # Each side has its own archive flag, so a conversation is hidden only for the
  # participant who archived it.
  scope :visible_for, lambda { |user|
    for_user(user).where(
      "(conversations.buyer_id = :id AND conversations.buyer_archived = FALSE) OR " \
      "(conversations.seller_id = :id AND conversations.seller_archived = FALSE)",
      id: user.id
    )
  }

  def self.between(first, second, listing: nil, store: nil)
    scope = for_user(first).for_user(second)
    scope = if listing.present?
      scope.where(listing_id: listing.id)
    else
      scope.where(store_id: store.id, listing_id: nil)
    end
    scope.first
  end

  def participant?(user)
    return false if user.blank?

    buyer_id == user.id || seller_id == user.id
  end

  def other_party_for(user)
    buyer_side?(user) ? seller : buyer
  end

  def buyer_side?(user)
    buyer_id == user.id
  end

  def unread_count_for(user)
    return 0 unless participant?(user)

    buyer_side?(user) ? buyer_unread_count : seller_unread_count
  end

  def unread_total
    buyer_unread_count + seller_unread_count
  end

  def archived_for?(user)
    buyer_side?(user) ? buyer_archived? : seller_archived?
  end

  # Marks every message sent by the other party as read and resets the badge.
  def mark_read_for!(user)
    return 0 unless participant?(user)

    count = messages.where.not(sender_id: user.id).where(read_at: nil).update_all(read_at: Time.current)
    column = buyer_side?(user) ? :buyer_unread_count : :seller_unread_count
    update_columns(column => 0, updated_at: Time.current)
    count
  end

  # Updates the recipient's badge and the ordering timestamp after a message.
  def register_message!(message)
    recipient_unread = message.sender_id == buyer_id ? :seller_unread_count : :buyer_unread_count
    recipient_archived = message.sender_id == buyer_id ? :seller_archived : :buyer_archived

    self.class.increment_counter(recipient_unread, id)
    self.class.where(id: id).update_all(
      last_message_at: message.created_at,
      recipient_archived => false,
      updated_at: Time.current
    )
    reload
  end

  def listing_context?
    listing.present?
  end

  def display_title
    listing&.title.presence || store.name
  end

  private

  def buyer_is_not_seller
    return if buyer_id.blank? || seller_id.blank?
    return if buyer_id != seller_id

    errors.add(:buyer_id, I18n.t("conversations.errors.self"))
  end

  def store_matches_seller
    return if store.blank? || seller.blank?
    return if store.user_id == seller_id

    errors.add(:seller_id, I18n.t("conversations.errors.seller_mismatch"))
  end

  def listing_matches_store
    return if listing.blank? || store.blank?

    return if listing.store_id == store_id && listing.user_id == seller_id

    errors.add(:listing_id, I18n.t("conversations.errors.listing_mismatch"))
  end

  def parties_not_blocked
    return unless Block.between?(buyer, seller)

    errors.add(:base, I18n.t("conversations.errors.blocked"))
  end

  def within_conversation_rate_limit
    return if buyer_id.blank?

    count = self.class.where(buyer_id: buyer_id).where(created_at: 1.hour.ago..).count
    return if count < MAX_NEW_PER_HOUR

    errors.add(:base, I18n.t("conversations.errors.rate_limited", max: MAX_NEW_PER_HOUR))
  end
end
