# frozen_string_literal: true

module Users
  # Creates or links a User from an OmniAuth authentication hash.
  class FromOmniauth
    def initialize(auth)
      @auth = auth
    end

    def call
      User.transaction do
        user = User.find_by(provider: auth.provider, uid: auth.uid)
        next user if user

        user = User.find_or_initialize_by(email: email)
        assign_identity(user)
        user.save!
        user
      end
    end

    private

    attr_reader :auth

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
