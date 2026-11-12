# frozen_string_literal: true

module Api
  module V1
    class CurrentSessionsController < AuthenticatedController
      def destroy
        current_api_session&.revoke!
        head :no_content
      end
    end
  end
end
