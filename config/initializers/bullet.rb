# frozen_string_literal: true

# Bullet catches N+1 queries and unused eager loading. It is active in
# development (logged and shown in the page footer) and in test, where it
# raises so regressions fail the suite instead of silently slowing pages down.
if defined?(Bullet)
  Bullet.enable = Rails.env.local? && ENV["BULLET_DISABLED"] != "1"
  Bullet.alert = false
  Bullet.bullet_logger = true
  Bullet.rails_logger = Rails.env.development?
  Bullet.add_footer = false
  Bullet.raise = Rails.env.test?
  Bullet.counter_cache_enable = false
  # Listing/Category/Store counters are maintained by explicit after_commit
  # callbacks on purpose (see project.md), so Bullet's counter-cache check does
  # not apply. Unused eager loading is also disabled: many relations are
  # intentionally preloaded for fragment-cached partials that only touch the
  # association on a cold render.
  Bullet.unused_eager_loading_enable = false
  Bullet.n_plus_one_query_enable = true

  # A few intentionally lazy loads happen outside a render (background jobs are
  # not exercised here) — keep the noisy request log useful.
  Bullet.stacktrace_includes = %w[app/controllers app/views app/helpers app/queries app/serializers]
end
