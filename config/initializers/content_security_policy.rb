# frozen_string_literal: true

# Content Security Policy. Nonces protect the inline theme boot script and
# importmap tags; third-party origins are limited to Google Fonts, Stripe
# (checkout + fraud frames) and the configured Active Storage host.
Rails.application.configure do
  storage_origins = [
    ENV["ACTIVE_STORAGE_HOST"].presence,
    ENV["S3_ENDPOINT"].presence,
    ENV["R2_ENDPOINT"].presence
  ].compact.map { |origin| origin.start_with?("http") ? origin : "https://#{origin}" }

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri :self
    policy.object_src :none
    policy.frame_ancestors :none
    policy.form_action :self
    policy.worker_src :self, :blob
    policy.manifest_src :self
    policy.font_src :self, "https://fonts.gstatic.com", :data
    policy.style_src :self, "https://fonts.googleapis.com", :unsafe_inline
    policy.script_src :self, "https://js.stripe.com"
    policy.connect_src :self, "https://api.stripe.com", "https://*.stripe.com", *storage_origins
    policy.img_src :self, :data, :blob, "https://*.stripe.com", *storage_origins
    policy.frame_src "https://js.stripe.com", "https://hooks.stripe.com", "https://m.stripe.network"
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
  # Report-only while developing; enforced in test and production.
  config.content_security_policy_report_only = Rails.env.development?
end
