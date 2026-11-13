# frozen_string_literal: true

module Api
  module V1
    class AddressesController < AuthenticatedController
      before_action :set_address, only: %i[update destroy]

      def index
        authorize Address
        collection_response(policy_scope(Address).default_first, AddressSerializer)
      end

      def create
        address = current_user.addresses.build(address_params)
        authorize address
        address.save!
        render_resource(address, AddressSerializer, status: :created)
      end

      def update
        authorize @address
        @address.update!(address_params)
        render_resource(@address, AddressSerializer)
      end

      def destroy
        authorize @address
        @address.destroy!
        head :no_content
      end

      private

      def set_address
        @address = current_user.addresses.find(params[:id])
      end

      def address_params
        params.require(:address).permit(
          :full_name, :line1, :line2, :city, :region_id, :postal_code,
          :country_code, :phone, :default
        )
      end
    end
  end
end
