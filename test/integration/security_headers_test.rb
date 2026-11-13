# frozen_string_literal: true

require "test_helper"

# Launch hardening contract: enforced CSP with per-request nonces, referrer and
# permissions policies, frame denial and Devise's anti-enumeration mode.
class SecurityHeadersTest < ActionDispatch::IntegrationTest
  test "HTML responses carry the enforced security headers" do
    get "/"

    assert_response :success
    csp = response.headers["Content-Security-Policy"]
    assert csp.present?, "missing Content-Security-Policy header"
    assert_includes csp, "default-src 'self'"
    assert_includes csp, "object-src 'none'"
    assert_includes csp, "frame-ancestors 'none'"
    assert_includes csp, "https://js.stripe.com"

    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
    assert_equal "DENY", response.headers["X-Frame-Options"]
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_includes response.headers["Permissions-Policy"], "camera=()"
    assert_includes response.headers["Permissions-Policy"], "geolocation=()"
  end

  test "every executable inline script uses the request nonce" do
    get "/"
    assert_response :success

    csp = response.headers["Content-Security-Policy"]
    nonce = csp[/'nonce-([^']+)'/, 1]
    assert nonce.present?, "CSP header has no nonce"

    doc = Nokogiri::HTML(response.body)
    executable = doc.css("script").reject do |script|
      script["src"].present? || script["type"].to_s == "application/ld+json"
    end

    assert executable.any?, "expected the theme/importmap inline scripts"
    executable.each do |script|
      assert_equal nonce, script["nonce"], "inline script without the CSP nonce: #{script.text[0, 60].inspect}"
    end

    importmap = doc.at_css('script[type="importmap"]')
    assert importmap.present?
    assert_equal nonce, importmap["nonce"]
  end

  test "API JSON responses also carry the hardening headers" do
    get "/api/v1/categories"

    assert_response :success
    assert_equal "application/json", response.media_type
    assert response.headers["Content-Security-Policy"].present?
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
  end

  test "Devise is in paranoid mode and session cookies are HttpOnly and SameSite" do
    assert Devise.paranoid

    options = Rails.application.config.session_options
    assert_equal "_pcmarket_session", options[:key]
    assert_equal true, options[:httponly]
    assert_equal :lax, options[:same_site]
  end
end
