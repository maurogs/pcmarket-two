# frozen_string_literal: true

module Sell
  # Builds the initial draft with the seller's store address defaults. Shared by
  # the HTML wizard and the JSON API so both start from the same state.
  class BuildListing
    def initialize(user:)
      @user = user
    end

    def call
      store = user.store
      region = store.region ||
               Region.find_by(country_code: store.country_code, name: store.province)

      user.listings.build(
        store: store,
        seller: user,
        country_code: store.country_code.presence || "ES",
        currency: "EUR",
        region: region,
        city: store.city,
        postal_code: store.postal_code,
        quantity: 1,
        handling_days: 3,
        shipping_mode: :shipping,
        allow_offers: store.allow_offers_default
      )
    end

    private

    attr_reader :user
  end
end
