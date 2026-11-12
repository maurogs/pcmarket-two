# frozen_string_literal: true

require "digest"
require "json"

module RackAttackSupport
  module_function

  def bearer_token(request)
    request.get_header("HTTP_AUTHORIZATION").to_s[/\ABearer\s+(.+)\z/i, 1]&.strip
  end

  # Reads an email from JSON or form-encoded bodies without consuming the body
  # for the downstream Rails app.
  def json_param(request, key)
    body = request.body
    return if body.nil?

    raw = body.read
    body.rewind

    return if raw.blank?

    data = JSON.parse(raw)
    data[key].to_s.strip.downcase.presence
  rescue JSON::ParserError, IOError
    nil
  end
end

Rack::Attack.cache.store =
  if Rails.env.test?
    ActiveSupport::Cache::MemoryStore.new
  else
    Rails.cache
  end

# Health checks must never be throttled by probes.
Rack::Attack.safelist("health check") { |request| request.path == "/up" }

# 300 requests / 5 minutes per bearer token (or IP for anonymous calls).
Rack::Attack.throttle("api/requests", limit: 300, period: 5.minutes) do |request|
  next unless request.path.start_with?("/api/v1/")

  token = RackAttackSupport.bearer_token(request)
  token.present? ? "token:#{Digest::SHA256.hexdigest(token)}" : "ip:#{request.ip}"
end

# 10 sign-in attempts / minute per IP and per email.
Rack::Attack.throttle("api/sign_in/ip", limit: 10, period: 1.minute) do |request|
  next unless request.post? && request.path == "/api/v1/sessions"

  request.ip
end

Rack::Attack.throttle("api/sign_in/email", limit: 10, period: 1.minute) do |request|
  next unless request.post? && request.path == "/api/v1/sessions"

  email = RackAttackSupport.json_param(request, "email")
  email.present? ? "email:#{email}" : nil
end

# 5 sign-ups / hour per IP.
Rack::Attack.throttle("api/sign_up/ip", limit: 5, period: 1.hour) do |request|
  next unless request.post? && request.path == "/api/v1/registrations"

  request.ip
end

# HTML form protection (locale prefix optional).
Rack::Attack.throttle("html/sign_in/ip", limit: 10, period: 1.minute) do |request|
  next unless request.post? && request.path.match?(%r{/users/sign_in\z})

  request.ip
end

Rack::Attack.throttle("html/sign_up/ip", limit: 5, period: 1.hour) do |request|
  next unless request.post? && request.path.match?(%r{/users\z})

  request.ip
end

Rack::Attack.throttle("html/contact/ip", limit: 10, period: 1.hour) do |request|
  next unless request.post? && request.path.match?(%r{/contact\z})

  request.ip
end

# Password reset requests: 5/hour per IP and per email.
Rack::Attack.throttle("html/password_reset/ip", limit: 5, period: 1.hour) do |request|
  next unless request.post? && request.path.match?(%r{/users/password\z})

  request.ip
end

Rack::Attack.throttle("html/password_reset/email", limit: 5, period: 1.hour) do |request|
  next unless request.post? && request.path.match?(%r{/users/password\z})

  email = request.params["user"].is_a?(Hash) ? request.params["user"]["email"] : nil
  email.present? ? "email:#{email.downcase}" : nil
end

# Newsletter double opt-in requests.
Rack::Attack.throttle("html/newsletter/ip", limit: 30, period: 1.hour) do |request|
  next unless request.post? && request.path.match?(%r{/newsletter\z})

  request.ip
end

# Chat messages in the HTML inbox (the model also enforces per-sender limits).
Rack::Attack.throttle("html/messages/ip", limit: 60, period: 10.minutes) do |request|
  next unless request.post? && request.path.match?(%r{/inbox/\d+/messages\z})

  request.ip
end

# Chat messages in the API.
Rack::Attack.throttle("api/messages/ip", limit: 60, period: 10.minutes) do |request|
  next unless request.post? && request.path.match?(%r{/api/v1/conversations/\d+/messages\z})

  token = RackAttackSupport.bearer_token(request)
  token.present? ? "token:#{Digest::SHA256.hexdigest(token)}" : "ip:#{request.ip}"
end

Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"] || {}
  period = match_data[:period].to_i
  period = 60 unless period.positive?
  retry_after = [ period - (Time.now.to_i % period), 1 ].max

  locale =
    begin
      Localization.locale_from_header(request.get_header("HTTP_ACCEPT_LANGUAGE")) ||
        I18n.default_locale
    rescue StandardError
      I18n.default_locale
    end

  body = {
    error: {
      code: "rate_limited",
      message: I18n.t("api.errors.rate_limited", locale: locale),
      details: nil
    }
  }.to_json

  [
    429,
    {
      "Content-Type" => "application/json; charset=utf-8",
      "Retry-After" => retry_after.to_s
    },
    [ body ]
  ]
end
