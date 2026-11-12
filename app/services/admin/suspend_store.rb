# frozen_string_literal: true

module Admin
  # Suspends a storefront with a reason and notifies the seller. Published
  # listings disappear from the marketplace because Listing.visible requires an
  # active store.
  class SuspendStore
    def initialize(store:, actor:, reason:)
      @store = store
      @actor = actor
      @reason = reason.to_s.strip
    end

    def call
      return false if @reason.blank?

      @store.update!(status: "suspended")
      AdminMailer.store_suspended(@store, @reason).deliver_later
      true
    end
  end
end
