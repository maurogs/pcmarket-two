# frozen_string_literal: true

module Api
  module V1
    class BaseSerializer
      include Alba::Resource

      class << self
        def image_host
          ENV["API_IMAGE_HOST"].presence ||
            ENV["APP_HOST"].presence ||
            Rails.application.routes.default_url_options[:host].presence ||
            "localhost:3000"
        end

        def image_protocol
          ENV["API_IMAGE_PROTOCOL"].presence || (Rails.env.production? ? "https" : "http")
        end

        def image_url_options
          { host: image_host, protocol: image_protocol }
        end
      end

      private

      # Absolute URL for an Active Storage attachment variant. Returns nil for
      # unattached records so clients can fall back to a placeholder.
      def attachment_url(attachment, variant: :thumb)
        return if attachment.blank? || !attachment.attached?

        representation = variant.is_a?(Hash) ? attachment.variant(variant) : attachment.variant(variant)
        Rails.application.routes.url_helpers.rails_representation_url(
          representation, **self.class.image_url_options
        )
      rescue StandardError
        nil
      end

      def timestamp(value)
        value&.iso8601
      end

      def date(value)
        value&.iso8601
      end

      def money(cents, currency = "EUR")
        return if cents.nil?

        ActiveSupport::NumberHelper.number_to_currency(
          BigDecimal(cents.to_i) / 100, unit: currency == "EUR" ? "€" : currency, format: "%n %u"
        )
      end

      def localized_event_body(message)
        return message.body unless message.event?

        values = (message.metadata || {}).to_h.symbolize_keys
        if values.key?(:amount_cents)
          values[:amount] = money(values.delete(:amount_cents), values[:currency] || "EUR")
        end
        I18n.t(message.body, **values)
      rescue I18n::MissingTranslationData, I18n::MissingInterpolationArgument
        message.body
      end
    end
  end
end
