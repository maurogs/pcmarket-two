# frozen_string_literal: true

class Notification < ApplicationRecord
  KINDS = %w[
    listing_approved
    listing_rejected
    new_sale
    order_shipped
    order_delivered
    order_cancelled
    price_drop
    followed_store_new_listing
    saved_search_match
    new_message
    new_offer
    offer_accepted
    offer_declined
    offer_countered
    offer_expired
    offer_expiring
  ].freeze

  # Email alerts that honour the recipient's email preference.
  ALERT_KINDS = %w[price_drop followed_store_new_listing saved_search_match].freeze

  # Marketing kinds will require the user's explicit marketing opt-in.
  MARKETING_KINDS = [].freeze

  belongs_to :recipient, class_name: "User", inverse_of: :notifications
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :kind, inclusion: { in: KINDS }
  validate :params_is_a_hash

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc, id: :desc) }
  scope :latest, -> { recent.limit(10) }

  # Distinct callback methods: Rails collapses duplicate filter symbols on the
  # commit chain, so sharing one method would drop the create/destroy callbacks.
  after_create_commit :expire_and_broadcast_after_create
  after_update_commit :expire_and_broadcast_after_update, if: :saved_change_to_read_at?
  after_destroy_commit :expire_and_broadcast_after_destroy

  def mark_read!
    return if read_at.present?

    update!(read_at: Time.current)
    self.class.expire_unread_cache(recipient)
  end

  def self.unread_count_for(user)
    return 0 if user.blank?

    Rails.cache.fetch([ "notifications/unread_count", user.id ], expires_in: 5.minutes) do
      where(recipient_id: user.id, read_at: nil).count
    end
  end

  def self.expire_unread_cache(user)
    return if user.blank?

    Rails.cache.delete([ "notifications/unread_count", user.id ])
  end

  def self.broadcast_bell(user)
    return if user.blank?

    locale = user.locale.presence || I18n.default_locale
    I18n.with_locale(locale) do
      Turbo::StreamsChannel.broadcast_replace_later_to(
        [ user, :notifications ],
        target: "notifications-bell",
        partial: "shared/notifications_bell",
        locals: { user: user, locale: locale }
      )
    end
  end

  private

  def params_is_a_hash
    return if params.is_a?(Hash)

    errors.add(:params, I18n.t("notifications.errors.invalid_params"))
  end

  def expire_and_broadcast
    self.class.expire_unread_cache(recipient)
    self.class.broadcast_bell(recipient)
  end

  def expire_and_broadcast_after_create
    expire_and_broadcast
  end

  def expire_and_broadcast_after_update
    expire_and_broadcast
  end

  def expire_and_broadcast_after_destroy
    expire_and_broadcast
  end
end
