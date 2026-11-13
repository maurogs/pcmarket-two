# frozen_string_literal: true

module Payments
  # Raised when production starts without the Stripe keys it needs.
  ConfigurationError = Class.new(StandardError)

  # Falls back to ENV so container deployments can inject secrets at runtime.
  def self.stripe_secret_key
    credentials_key(:secret_key) || ENV["STRIPE_SECRET_KEY"].presence
  end

  def self.stripe_publishable_key
    credentials_key(:publishable_key) || ENV["STRIPE_PUBLISHABLE_KEY"].presence
  end

  def self.stripe_webhook_secret
    credentials_key(:webhook_secret) || ENV["STRIPE_WEBHOOK_SECRET"].presence
  end

  def self.stripe_configured?
    stripe_secret_key.present? && stripe_publishable_key.present?
  end

  # Test and key-less development installs simulate payments deterministically.
  def self.fake_gateway?
    Rails.env.test? || (Rails.env.development? && !stripe_configured?)
  end

  def self.test_mode_banner?
    Rails.env.development? && !stripe_configured?
  end

  # The single payment boundary used by the checkout, refunds and payouts.
  def self.gateway(failure: false, env: Rails.env)
    environment = ActiveSupport::StringInquirer.new(env.to_s)

    return FakeGateway.new(failure: failure) if environment.test?
    return StripeGateway.new if stripe_configured?
    return FakeGateway.new(failure: failure) if environment.development? || environment.local?

    raise ConfigurationError, "Stripe is not configured: set the secret and publishable keys"
  end

  def self.credentials_key(name)
    Rails.application.credentials.dig(:stripe, name).presence
  end

  private_class_method :credentials_key
end
