# frozen_string_literal: true

module Api
  module V1
    # Consistent error envelope and rescue handlers shared by every endpoint.
    module ErrorHandling
      extend ActiveSupport::Concern

      included do
        rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
        rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized
        rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
        rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
        rescue_from AASM::InvalidTransition, with: :render_invalid_transition
        rescue_from Api::V1::Error, with: :render_api_error
      end

      private

      def render_api_error(error)
        render_error(code: error.code, status: error.status,
                     message_key: error.message_key, details: error.details)
      end

      def render_record_not_found(_error)
        render_error(code: "not_found", status: :not_found,
                     message_key: "api.errors.not_found")
      end

      def render_not_authorized(_error)
        render_error(code: "forbidden", status: :forbidden,
                     message_key: "api.errors.forbidden")
      end

      def render_parameter_missing(error)
        render_error(
          code: "validation_failed",
          status: :unprocessable_content,
          message_key: "api.errors.validation_failed",
          details: { error.param.to_s => [ I18n.t("api.errors.required", locale: error_locale) ] }
        )
      end

      def render_record_invalid(error)
        render_error(
          code: "validation_failed",
          status: :unprocessable_content,
          message_key: "api.errors.validation_failed",
          details: validation_details(error.record)
        )
      end

      def render_invalid_transition(_error)
        render_error(code: "conflict", status: :conflict,
                     message_key: "api.errors.conflict")
      end

      def validation_details(record)
        record.errors.to_hash(true).transform_keys(&:to_s)
      end

      def render_error(code:, status:, message_key:, details: nil)
        payload = {
          error: {
            code: code.to_s,
            message: I18n.t(message_key, locale: error_locale),
            details: details
          }
        }
        render json: payload, status: status
      end
    end
  end
end
