# frozen_string_literal: true

# CORS applies only to the versioned JSON API. Native apps do not need it, but
# browser-based admin tools and the API explorer do. Configure the allow-list
# with CORS_ALLOWED_ORIGINS (comma separated); "*" is the development default.
allowed_origins = ENV.fetch("CORS_ALLOWED_ORIGINS", "*")
                     .split(",")
                     .map(&:strip)
                     .reject(&:empty?)

if defined?(Rack::Cors) && allowed_origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*allowed_origins)
      resource "/api/*",
               headers: :any,
               methods: %i[get post put patch delete options head],
               expose: %w[Link X-Total-Count ETag Last-Modified Retry-After],
               max_age: 600
    end
  end
end
