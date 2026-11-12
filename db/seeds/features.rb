# frozen_string_literal: true

# Every feature starts disabled; admins turn them on from /admin/features.
# FeatureFlag rows carry the translated description key used by that screen.
features = %i[
  sell_to_us
  commissions
  featured_listings
  google_login
  offers
  guest_checkout
].freeze

features.each do |feature|
  existed = Flipper.exist?(feature)
  Flipper.add(feature)
  Flipper.disable(feature) unless existed
  FeatureFlag.find_or_initialize_by(key: feature.to_s).tap do |flag|
    flag.description_key = "admin.features.descriptions.#{feature}"
    flag.save!
  end
end
