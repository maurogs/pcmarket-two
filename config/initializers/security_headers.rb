# frozen_string_literal: true

# Hardening headers applied to every response. X-Frame-Options is DENY: the
# marketplace never needs to be embedded, and Stripe's Payment Element uses
# outbound frames from our pages (allowed by the CSP frame-src).
Rails.application.config.action_dispatch.default_headers.merge!(
  "X-Frame-Options" => "DENY",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "X-Content-Type-Options" => "nosniff",
  "X-Permitted-Cross-Domain-Policies" => "none",
  "X-XSS-Protection" => "0",
  # Rails 8 still emits the legacy Feature-Policy header from
  # config.permissions_policy; send the modern syntax as well.
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=(), usb=(), payment=(self)"
)
