# frozen_string_literal: true

module Api
  module V1
    class StripeConnectsController < AuthenticatedController
      def create
        store = current_user.store
        raise ActiveRecord::RecordNotFound if store.blank?

        authorize store, :update?

        url = Payments::ConnectOnboarding.new(
          store: store,
          refresh_url: mobile_return_url,
          return_url: mobile_return_url
        ).call

        render_data({ url: url })
      rescue Payments::ConnectOnboarding::Error
        raise Api::V1::Error.conflict(message_key: "store_payments.errors.onboarding_failed")
      end

      private

      def mobile_return_url
        ENV["MOBILE_CONNECT_RETURN_URL"].presence || "pcmarket://stripe/connect"
      end
    end
  end
end
