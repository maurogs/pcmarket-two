# frozen_string_literal: true

module Api
  module V1
    # API locale negotiation: Accept-Language first, then the signed-in user's
    # stored locale, then the site default. No cookies are written.
    module Locale
      extend ActiveSupport::Concern

      private

      def switch_locale(&action)
        @api_locale = detected_api_locale
        I18n.with_locale(@api_locale, &action)
      end

      def detected_api_locale
        Localization.locale_from_header(request.headers["Accept-Language"]) ||
          Localization.normalize(current_user&.locale) ||
          I18n.default_locale
      end

      # Rescue handlers run outside the around_action in some Rails versions,
      # so errors keep the negotiated locale explicitly.
      def error_locale
        @api_locale ||
          Localization.locale_from_header(request.headers["Accept-Language"]) ||
          Localization.normalize(current_user&.locale) ||
          I18n.default_locale
      end
    end
  end
end
