require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings.
  config.eager_load = true

  # Full error reports are disabled; ErrorsController renders branded pages.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Optional CDN in front of /assets and Active Storage URLs.
  config.asset_host = ENV["ASSET_HOST"] if ENV["ASSET_HOST"].present?

  # Uploads: S3 (AWS) or Cloudflare R2 when ACTIVE_STORAGE_SERVICE is set,
  # local disk otherwise. See config/storage.yml.
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym

  # Assume TLS is terminated by the proxy and redirect anything plain HTTP.
  config.assume_ssl = true
  config.force_ssl = true
  config.ssl_options = {
    redirect: { exclude: ->(request) { request.path == "/up" } },
    hsts: { subdomains: true, preload: true, expires: 1.year }
  }

  # Host allow-list from APP_HOST/APP_HOSTS (comma separated). Always allow /up.
  allowed_hosts = [ ENV["APP_HOST"], *ENV.fetch("APP_HOSTS", "").split(",") ]
                  .map(&:strip).reject(&:blank?).uniq
  config.hosts = allowed_hosts if allowed_hosts.any?
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # Structured logs with request ids.
  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  config.active_support.report_deprecations = false

  # Solid Cache is the production cache store.
  config.cache_store = :solid_cache_store

  # Solid Queue runs in Puma (SOLID_QUEUE_IN_PUMA) or as a separate worker.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Transactional email through a real SMTP provider. Delivery is queued with
  # Solid Queue (deliver_later) so requests never block on SMTP.
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.deliver_later_queue_name = :mailers
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "localhost"),
    protocol: "https"
  }

  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_ADDRESS"),
      port: ENV.fetch("SMTP_PORT", 587).to_i,
      domain: ENV.fetch("SMTP_DOMAIN", ENV.fetch("APP_HOST", "localhost")),
      user_name: ENV["SMTP_USER"],
      password: ENV["SMTP_PASSWORD"],
      authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
      enable_starttls_auto: ENV.fetch("SMTP_STARTTLS", "true") == "true"
    }
  end

  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]
end
