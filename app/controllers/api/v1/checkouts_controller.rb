# frozen_string_literal: true

module Api
  module V1
    class CheckoutsController < AuthenticatedController
      def create
        authorize Checkout, :create?
        cart = current_user.cart
        raise Api::V1::Error.validation_failed(
          details: { cart: [ I18n.t("checkout.errors.empty_cart", locale: error_locale) ] }
        ) if cart.blank? || cart.items.empty?

        result = Checkouts::Start.new(
          cart: cart,
          buyer: current_user,
          params: checkout_params,
          gateway: api_gateway
        ).call

        unless result.success?
          raise Api::V1::Error.validation_failed(details: { base: result.errors })
        end

        checkout = result.checkout
        payment = Payments::MobileSetup.new(user: current_user, gateway: api_gateway).call
        unless payment.success?
          raise Api::V1::Error.conflict(message_key: "api.checkout.payment_setup_failed")
        end

        render_data(
          {
            checkout: CheckoutSerializer.new(checkout).serializable_hash,
            payment: {
              publishable_key: payment.publishable_key,
              customer_id: payment.customer_id,
              ephemeral_key_secret: payment.ephemeral_key_secret,
              payment_intent_id: checkout.payment_intent_id,
              client_secret: checkout.payment_client_secret
            }
          },
          status: :created
        )
      end

      def show
        checkout = current_user.checkouts.includes(orders: [ :store, { items: :listing } ])
                            .find(params[:id])
        authorize checkout
        render_resource(checkout, CheckoutSerializer)
      end

      private

      def checkout_params
        params.permit(
          :email, :address_id, :save_address, :terms_accepted, :idempotency_key,
          :buy_now_listing_id,
          address: %i[full_name line1 line2 city region_id postal_code country_code phone],
          fulfilment: {}
        )
      end

      def api_gateway
        @api_gateway ||= if Payments.fake_gateway?
          Payments::FakeGateway.new(
            failure: params[:payment_result] == "failure",
            mobile: true
          )
        else
          Payments.gateway
        end
      end
    end
  end
end
