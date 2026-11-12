# frozen_string_literal: true

require "test_helper"

# Guards the performance configuration that the suite relies on: Bullet raises
# on N+1 queries in test, and Active Storage has a working variant processor on
# every machine (libvips when present, ImageMagick otherwise).
class PerformanceGuardTest < ActiveSupport::TestCase
  test "bullet raises on N+1 queries in test" do
    assert defined?(Bullet), "Bullet is not loaded in test"
    assert Bullet.enable?, "Bullet must be enabled in test"
    assert Bullet.n_plus_one_query_enable?
    assert_not Bullet.unused_eager_loading_enable?
    assert UniformNotifier::Raise.active?, "Bullet must raise (not just log) in test"
  end

  test "active storage has a variant processor available" do
    assert_includes %i[vips mini_magick], Rails.application.config.active_storage.variant_processor
  end
end
