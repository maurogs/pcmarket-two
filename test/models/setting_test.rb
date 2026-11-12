# frozen_string_literal: true

require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "set infers the type and persists the value" do
    Setting.set("commission_percent", 5.5)

    record = Setting.find_by!(key: "commission_percent")
    assert_equal "decimal", record.value_type
    assert_equal BigDecimal("5.5"), record.typed_value
  end

  test "get returns the typed value" do
    Setting.create!(key: "maintenance_mode", value: true, value_type: "boolean")
    Setting.create!(key: "max_images", value: 12, value_type: "integer")
    Setting.create!(key: "support_email", value: "help@example.com", value_type: "string")

    assert_equal true, Setting.get("maintenance_mode")
    assert_equal 12, Setting.get("max_images")
    assert_equal "help@example.com", Setting.get("support_email")
  end

  test "get returns the provided default for a missing key" do
    assert_equal 42, Setting.get("missing_key", 42)
    assert_nil Setting.get("missing_key")
  end

  test "get caches values and invalidates them after a commit" do
    store = ActiveSupport::Cache::MemoryStore.new

    with_cache(store) do
      Setting.create!(key: "greeting", value: "hello", value_type: "string")
      assert_equal "hello", Setting.get("greeting")

      Setting.find_by!(key: "greeting").update_column(:value, "stale")
      assert_equal "hello", Setting.get("greeting")

      Setting.find_by!(key: "greeting").update!(value: "fresh")
      assert_equal "fresh", Setting.get("greeting")
    end
  end

  test "set updates an existing setting" do
    Setting.create!(key: "featured_enabled", value: false, value_type: "boolean")

    Setting.set("featured_enabled", true)

    assert_equal true, Setting.get("featured_enabled")
    assert_equal 1, Setting.where(key: "featured_enabled").count
  end
end
