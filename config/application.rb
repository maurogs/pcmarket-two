require_relative "boot"
require_relative "../lib/canonical_url_middleware"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AppTestTwo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Madrid"

    # Prefer libvips when the native library is available (the production
    # Docker image installs it); fall back to ImageMagick everywhere else.
    config.active_storage.variant_processor =
      begin
        require "vips"
        :vips
      rescue LoadError
        :mini_magick
      end

    # Internationalisation: Spanish is the default, English is the fallback.
    config.i18n.available_locales = %i[es en fr de it pt]
    config.i18n.default_locale = :es
    config.i18n.fallbacks = [ :en, :es ]
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]

    # Active Record encryption protects buyback IBANs at rest. Production must
    # provide the three keys through credentials or ENV; development/test fall
    # back to local-only deterministic values so the app boots without secrets.
    encryption = Rails.application.credentials[:active_record_encryption] || {}
    fallback = Rails.env.local? || ENV["SECRET_KEY_BASE_DUMMY"] == "1"
    primary_key = encryption[:primary_key].presence ||
                  ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].presence ||
                  ("0123456789abcdef0123456789abcdef" if fallback)
    deterministic_key = encryption[:deterministic_key].presence ||
                        ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"].presence ||
                        ("abcdef0123456789abcdef0123456789" if fallback)
    key_derivation_salt = encryption[:key_derivation_salt].presence ||
                          ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"].presence ||
                          ("fedcba9876543210fedcba9876543210" if fallback)

    if [ primary_key, deterministic_key, key_derivation_salt ].any?(&:blank?)
      raise "Active Record encryption keys are missing. Set ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY, " \
            "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY and ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT " \
            "(or the equivalent credentials)."
    end

    config.active_record.encryption.primary_key = primary_key
    config.active_record.encryption.deterministic_key = deterministic_key
    config.active_record.encryption.key_derivation_salt = key_derivation_salt

    # Spanish canonical URLs have no /es prefix and public paths never keep a
    # trailing slash. Runs before static file serving so both are redirects.
    config.middleware.insert_before(ActionDispatch::Static, CanonicalUrlMiddleware)

    # Permissions-Policy must be configured before the middleware stack is
    # built, so it lives here rather than in an initializer.
    config.permissions_policy do |policy|
      policy.camera :none
      policy.microphone :none
      policy.geolocation :none
      policy.usb :none
      policy.payment :self
    end

    # Exceptions are rendered by ErrorsController with the branded, translated
    # error layout instead of the static public/*.html files.
    config.exceptions_app = ->(env) { Rails.application.routes.call(env) }

    # config.eager_load_paths << Rails.root.join("extras")
  end
end
