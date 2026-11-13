# frozen_string_literal: true

# Shared behaviour for the GPU and CPU model → performance tier tables. The
# longest matching pattern wins, so "rtx 4070 ti" beats "rtx 4070".
module TierPattern
  extend ActiveSupport::Concern

  included do
    validates :pattern, presence: true, uniqueness: true
    validates :tier, numericality: { only_integer: true, in: 1..10 }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:position, :tier, :id) }

    before_validation :normalise_pattern
  end

  class_methods do
    # Returns the tier for a free-text model name or nil when no pattern
    # matches. Matching is case-insensitive and pattern-length ordered.
    def tier_for(model_name)
      text = model_name.to_s.strip
      return nil if text.blank?

      active
        .where("REPLACE(LOWER(?), '-', ' ') LIKE '%' || REPLACE(pattern, '-', ' ') || '%'", text)
        .order(Arel.sql("LENGTH(pattern) DESC"), :tier)
        .pick(:tier)
    end
  end

  private

  def normalise_pattern
    self.pattern = pattern.to_s.strip.downcase.presence
  end
end
