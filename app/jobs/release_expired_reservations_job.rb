# frozen_string_literal: true

# Releases stock held by checkouts whose 15-minute payment window has lapsed.
# Scheduled from config/recurring.yml every minute.
class ReleaseExpiredReservationsJob < ApplicationJob
  queue_as :default

  def perform
    Checkout.expired.find_each do |checkout|
      Checkouts::Expire.new(checkout: checkout).call
    end
  end
end
