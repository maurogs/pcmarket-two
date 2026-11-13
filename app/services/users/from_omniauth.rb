# frozen_string_literal: true

module Users
  # Creates or links a User from an OmniAuth authentication hash.
  class FromOmniauth
    EMAIL_VERIFIED_PATHS = [
      %w[extra raw_info email_verified],
      %w[info email_verified]
    ].freeze

    def initialize(auth)
      @auth = auth
    end

    def call
      User.transaction do
        user = User.find_by(provider: auth.provider, uid: auth.uid)
        next user if user

        user = User.find_or_initialize_by(email: email)
        next reject_unverified_link(user) if user.persisted? && !email_verified?

        assign_identity(user)
        user.save!
        user
      end
    end

    private

    attr_reader :auth

    # Never link a Google identity to an existing account unless Google
    # reports the email as verified. The account is left untouched.
    def reject_unverified_link(user)
      user.errors.add(:email, I18n.t("auth.omniauth_email_not_verified"))
      user
    end

    def email_verified?
      EMAIL_VERIFIED_PATHS.any? do |path|
        ActiveModel::Type::Boolean.new.cast(dig_auth(*path))
      end
    end

    def dig_auth(*keys)
      keys.reduce(auth) do |value, key|
        return nil unless value.respond_to?(:key?) && value.respond_to?(:[])

        if value.key?(key)
          value[key]
        elsif value.key?(key.to_sym)
          value[key.to_sym]
        else
          return nil
        end
      end
    end

    def assign_identity(user)
      user.provider = auth.provider
      user.uid = auth.uid
      user.first_name ||= auth.info.first_name
      user.last_name ||= auth.info.last_name
      user.username = unique_username if user.username.blank?

      if user.new_record?
        user.password = SecureRandom.hex(32)
        user.confirmed_at ||= Time.current
        user.terms_accepted = "1"
      end
    end

    def email
      auth.info.email.to_s.downcase
    end

    def unique_username
      base = (auth.info.nickname.presence || email.split("@").first).to_s
      base = base.gsub(/[^a-zA-Z0-9_-]/, "").slice(0, 24)
      base = "user#{SecureRandom.hex(4)}" if base.length < 3

      candidate = base
      candidate = "#{base.slice(0, 24)}-#{SecureRandom.hex(3)}" while User.exists?(username: candidate)
      candidate
    end
  end
end
