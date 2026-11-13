# frozen_string_literal: true

# Session and cart cookies are first-party, HttpOnly and SameSite=Lax. Secure
# is enabled in production behind the TLS-terminating proxy.
Rails.application.config.session_store :cookie_store,
                                       key: "_pcmarket_session",
                                       same_site: :lax,
                                       httponly: true,
                                       secure: Rails.env.production?
