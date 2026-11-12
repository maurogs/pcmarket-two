# frozen_string_literal: true

class ListingModeration < ApplicationRecord
  REJECTION_REASONS = %w[
    prohibited_item
    misleading_description
    poor_photos
    wrong_category
    price_suspicious
    contact_info_in_listing
    duplicate
    other
  ].freeze

  belongs_to :listing
  belongs_to :moderator, class_name: "User"

  enum :action, {
    approved: 0,
    rejected: 1,
    archived: 2,
    restored: 3
  }, scopes: false

  validates :action, presence: true

  # Combines a predefined reason code with an optional note. The label is
  # translated in the seller's locale because the stored string is what the
  # seller sees in the email and on their listing page.
  def self.compose_reason(code:, text:, locale:)
    normalized_code = code.to_s.strip
    note = text.to_s.strip
    label = if REJECTION_REASONS.include?(normalized_code)
      I18n.t("admin.moderation.reasons.#{normalized_code}",
             locale: locale.presence || I18n.default_locale)
    end

    [ label, note.presence ].compact.join(" — ").presence
  end
end
