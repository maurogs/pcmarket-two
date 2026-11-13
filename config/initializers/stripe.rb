# frozen_string_literal: true

# The app constant is autoloaded, so the key is read once the application has
# finished booting (and again after code reloads in development).
Rails.application.config.to_prepare do
  Stripe.api_key = Payments.stripe_secret_key if Payments.stripe_secret_key.present?
end
