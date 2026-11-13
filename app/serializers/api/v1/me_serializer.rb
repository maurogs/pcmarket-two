# frozen_string_literal: true

module Api
  module V1
    class MeSerializer < BaseSerializer
      attributes :id, :username, :email, :first_name, :last_name, :phone,
                 :locale, :country_code, :role, :marketing_opt_in,
                 :terms_accepted_at, :created_at, :updated_at

      attribute :confirmed do |user|
        user.confirmed?
      end

      attribute :display_name, &:display_name
      attribute :avatar_url do |user|
        attachment_url(user.avatar, variant: { resize_to_limit: [ 256, 256 ], format: :webp })
      end
      attribute :unconfirmed_email, &:unconfirmed_email

      attribute :notification_preferences do |user|
        NotificationPreference.settings_for(user).map do |kind, preference|
          { kind: kind, in_app: preference.in_app, email: preference.email }
        end
      end
    end
  end
end
