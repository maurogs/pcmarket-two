# frozen_string_literal: true

module Api
  module V1
    # Updates the signed-in user's profile fields and notification preferences
    # in one transaction.
    class ProfileUpdate
      Result = Struct.new(:success, :user, :errors, keyword_init: true) do
        def success?
          success
        end
      end

      PROFILE_ATTRIBUTES = %w[
        first_name last_name username phone locale country_code marketing_opt_in
      ].freeze

      def initialize(user:, attributes:, preferences: nil)
        @user = user
        @attributes = attributes.to_h.with_indifferent_access.slice(*PROFILE_ATTRIBUTES)
        @preferences = preferences
      end

      def call
        User.transaction do
          @user.update!(@attributes)
          update_preferences!
        end

        Result.new(success: true, user: @user, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success: false, user: @user, errors: e.record.errors.full_messages)
      end

      private

      def update_preferences!
        return if @preferences.blank?

        preferences = if @preferences.respond_to?(:to_unsafe_h)
          @preferences.to_unsafe_h
        else
          @preferences.to_h
        end
        preferences.each do |kind, values|
          kind = kind.to_s
          next unless Notification::KINDS.include?(kind)

          values = if values.respond_to?(:to_unsafe_h)
            values.to_unsafe_h.with_indifferent_access
          else
            values.to_h.with_indifferent_access
          end
          preference = @user.notification_preferences.find_or_initialize_by(kind: kind)
          preference.in_app = values[:in_app] unless values[:in_app].nil?
          preference.email = values[:email] unless values[:email].nil?
          preference.save!
        end
      end
    end
  end
end
