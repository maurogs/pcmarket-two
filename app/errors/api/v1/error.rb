# frozen_string_literal: true

module Api
  module V1
    # Domain error rendered as the consistent API error envelope.
    class Error < StandardError
      attr_reader :code, :status, :message_key, :details

      def initialize(code:, status:, message_key:, details: nil)
        @code = code.to_s
        @status = status
        @message_key = message_key
        @details = details
        super(message_key)
      end

      def self.unauthorized(message_key: "api.errors.unauthorized", details: nil)
        new(code: "unauthorized", status: :unauthorized,
            message_key: message_key, details: details)
      end

      def self.forbidden(message_key: "api.errors.forbidden", details: nil)
        new(code: "forbidden", status: :forbidden,
            message_key: message_key, details: details)
      end

      def self.not_found(message_key: "api.errors.not_found", details: nil)
        new(code: "not_found", status: :not_found,
            message_key: message_key, details: details)
      end

      def self.validation_failed(details: nil, message_key: "api.errors.validation_failed")
        new(code: "validation_failed", status: :unprocessable_content,
            message_key: message_key, details: details)
      end

      def self.rate_limited(message_key: "api.errors.rate_limited")
        new(code: "rate_limited", status: :too_many_requests, message_key: message_key)
      end

      def self.conflict(message_key: "api.errors.conflict", details: nil)
        new(code: "conflict", status: :conflict,
            message_key: message_key, details: details)
      end

      def self.feature_disabled(message_key: "api.errors.feature_disabled")
        new(code: "feature_disabled", status: :not_found, message_key: message_key)
      end
    end
  end
end
