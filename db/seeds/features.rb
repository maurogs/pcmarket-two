# frozen_string_literal: true

# Every feature starts disabled; admins turn them on from /admin/flipper.
FEATURES = %i[
  sell_to_us
  commissions
  featured_listings
  google_login
  offers
  guest_checkout
].freeze

FEATURES.each do |feature|
  Flipper.add(feature)
  Flipper.disable(feature)
end
