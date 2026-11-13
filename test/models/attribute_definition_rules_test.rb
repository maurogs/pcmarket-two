# frozen_string_literal: true

require "test_helper"

class AttributeDefinitionRulesTest < ActiveSupport::TestCase
  test "the key is immutable after creation" do
    definition = attribute_definitions(:gpu_chipset)

    refute definition.update(key: "renamed_chipset")
    assert_includes definition.errors[:key], I18n.t("attribute_definitions.errors.key_immutable")
    assert_equal "gpu_chipset", definition.reload.key
  end

  test "the input type is locked once a listing uses the attribute" do
    definition = attribute_definitions(:gpu_chipset)
    assert_predicate definition, :used?

    refute definition.update(input_type: :multi_select)
    assert_includes definition.errors[:input_type], I18n.t("attribute_definitions.errors.input_type_locked")
    assert_equal "single_select", definition.reload.input_type
  end

  test "unused definitions can change input type and be deleted" do
    definition = AttributeDefinition.create!(
      key: "phase7b_unused", name: { es: "Sin usar", en: "Unused" },
      input_type: :text, position: 99
    )

    assert definition.update(input_type: :number, unit: "mm")
    definition.destroy!
    assert_not AttributeDefinition.exists?(definition.id)
  end

  test "an option value is locked while listings use it" do
    option = attribute_options(:chipset_nvidia)
    assert_predicate option, :used?

    refute option.update(value: "team_green")
    assert_includes option.errors[:value], I18n.t("attribute_definitions.errors.value_locked")
    assert_equal "nvidia", option.reload.value
  end

  test "usage counts come from one expanded jsonb query" do
    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:cached] || payload[:name] == "SCHEMA"
      next if payload[:sql].match?(/\A(BEGIN|COMMIT|SAVEPOINT|RELEASE SAVEPOINT)/)
      next unless payload[:sql].include?("FROM listings")

      queries << payload[:sql]
    end

    counts = nil
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      counts = Admin::AttributeUsage.for(attribute_definitions(:gpu_chipset))
    end

    assert_equal 1, queries.size
    assert_equal scalar_usage("gpu_chipset", "nvidia"), counts["nvidia"]
    assert_equal scalar_usage("gpu_chipset", "amd"), counts["amd"]
    assert_operator counts["nvidia"], :>=, 1

    array_counts = Admin::AttributeUsage.for(attribute_definitions(:gpu_memory_type))
    assert_equal array_usage("gpu_memory_type", "gddr6x"), array_counts["gddr6x"]
    assert_equal array_usage("gpu_memory_type", "gddr6"), array_counts["gddr6"]
  end

  private

  def scalar_usage(key, value)
    Listing.where("specs @> ?::jsonb", { key => value }.to_json).count
  end

  def array_usage(key, value)
    Listing.where("specs @> ?::jsonb", { key => [ value ] }.to_json).count
  end
end
