# frozen_string_literal: true

# Metadata row for a Flipper feature, used by the admin feature-flag screen
# (translated description and an auditable record for toggles). Flipper itself
# remains the source of truth for the features and their gates.
class FeatureFlag < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.for(key)
    record = find_or_initialize_by(key: key.to_s)
    record.description_key ||= "admin.features.descriptions.#{key}"
    record
  end
end
