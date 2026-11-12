# frozen_string_literal: true

module Api
  module V1
    class MyStoresController < AuthenticatedController
      def show
        store = current_user.store
        raise ActiveRecord::RecordNotFound if store.blank?

        authorize store, :update?
        render_resource(store, StoreDetailSerializer)
      end

      def create
        store = current_user.build_store(country_code: "ES")
        authorize store
        assign_store(store)
        store.save!(context: :onboarding)
        render_resource(store, StoreDetailSerializer, status: :created)
      end

      def update
        store = current_user.store
        raise ActiveRecord::RecordNotFound if store.blank?

        authorize store, :update?
        assign_store(store)
        store.save!
        render_resource(store, StoreDetailSerializer)
      end

      private

      def assign_store(store)
        store.assign_attributes(store_params)
        signed_id = params[:logo_signed_id] || params.dig(:store, :logo_signed_id)
        return if signed_id.blank?

        blob = ActiveStorage::Blob.find_signed!(signed_id)
        store.logo.attach(blob)
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        raise Api::V1::Error.validation_failed(
          details: { logo: [ I18n.t("api.errors.invalid_signed_id", locale: error_locale) ] }
        )
      end

      def store_params
        params.require(:store).permit(
          :kind, :name, :description, :region_id, :city, :country_code,
          :legal_name, :tax_id, :address_line, :postal_code, :phone, :website,
          :return_policy, :shipping_policy, :handling_days
        )
      end
    end
  end
end
