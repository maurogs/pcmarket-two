# frozen_string_literal: true

module Api
  module V1
    class LegalPagesController < BaseController
      def show
        kind = params[:kind].to_s
        raise ActiveRecord::RecordNotFound unless LegalPage::KINDS.include?(kind)

        country = requested_country
        page = LegalPage.current(country: country, locale: I18n.locale, kind: kind)
        raise ActiveRecord::RecordNotFound if page.nil?

        cache_public_catalogue!
        return if conditional_get!(etag: [ page, I18n.locale ],
                                   last_modified: page.updated_at,
                                   public: current_user.nil?)

        render_resource(page, LegalPageSerializer)
      end

      private

      def requested_country
        requested = Country.find_by(code: params[:country].to_s.upcase)
        return requested if requested.present?

        user_country = Country.find_by(code: current_user&.country_code.to_s.upcase)
        return user_country if user_country.present?

        Country.find_by(code: Country.launched_codes.first) || Country.first
      end
    end
  end
end
