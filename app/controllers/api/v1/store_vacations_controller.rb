# frozen_string_literal: true

module Api
  module V1
    class StoreVacationsController < AuthenticatedController
      def show
        store = current_user.store
        raise ActiveRecord::RecordNotFound if store.blank?

        authorize store, :update?
        render_data(vacation_payload(store))
      end

      def update
        store = current_user.store
        raise ActiveRecord::RecordNotFound if store.blank?

        authorize store, :update?
        unless Stores::SetVacation.new(store: store, attributes: vacation_params).call
          raise ActiveRecord::RecordInvalid.new(store)
        end

        render_data(vacation_payload(store))
      end

      private

      def vacation_params
        params.require(:store).permit(:vacation_mode, :vacation_message, :vacation_until)
      end

      def vacation_payload(store)
        {
          vacation_mode: store.vacation_mode,
          vacation_message: store.vacation_message,
          vacation_until: store.vacation_until
        }
      end
    end
  end
end
