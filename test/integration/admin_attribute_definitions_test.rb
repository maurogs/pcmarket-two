# frozen_string_literal: true

require "test_helper"

class AdminAttributeDefinitionsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "the index searches and filters by group" do
    get admin_attribute_definitions_path(locale: :en, q: "chipset")
    assert_response :success
    assert_includes response.body, "gpu_chipset"
    assert_not_includes response.body, "gpu_vram"

    get admin_attribute_definitions_path(locale: :en, group: "general")
    assert_response :success
    assert_includes response.body, "warranty"
    assert_not_includes response.body, "gpu_chipset"
  end

  test "creates a definition and exposes the option manager" do
    post admin_attribute_definitions_path(locale: :en), params: {
      attribute_definition: {
        key: "phase7b_speed", name_es: "Velocidad", name_en: "Speed",
        group: "phase7b", input_type: "single_select", filterable: "1", active: "1", position: 90
      }
    }

    definition = AttributeDefinition.find_by!(key: "phase7b_speed")
    assert_redirected_to edit_admin_attribute_definition_path(definition, locale: :en)

    get edit_admin_attribute_definition_path(definition, locale: :en)
    assert_response :success
    assert_includes response.body, I18n.t("admin.attribute_definitions.options.title", locale: :en)

    post admin_attribute_definition_attribute_options_path(definition, locale: :en), params: {
      attribute_option: { value: "fast", label_es: "Rápido", label_en: "Fast", active: "1" }
    }

    option = definition.attribute_options.find_by!(value: "fast")
    assert_equal "Rápido", option.label_es
    assert_redirected_to edit_admin_attribute_definition_path(definition, locale: :en)
  end

  test "the input type and used option values cannot change" do
    definition = attribute_definitions(:gpu_chipset)

    patch admin_attribute_definition_path(definition, locale: :en), params: {
      attribute_definition: { input_type: "multi_select" }
    }

    assert_response :unprocessable_entity
    assert_equal "single_select", definition.reload.input_type

    option = attribute_options(:chipset_nvidia)
    patch admin_attribute_definition_attribute_option_path(definition, option, locale: :en),
          params: { attribute_option: { value: "team_green" } }

    assert_redirected_to edit_admin_attribute_definition_path(definition, locale: :en)
    assert_includes flash[:alert], I18n.t("attribute_definitions.errors.value_locked", locale: :en)
    assert_equal "nvidia", option.reload.value
  end

  test "bulk import skips existing values" do
    definition = attribute_definitions(:gpu_vram)

    post admin_attribute_definition_attribute_option_import_path(definition, locale: :en),
         params: { text: "8\n16\n16\n24" }

    assert_redirected_to edit_admin_attribute_definition_path(definition, locale: :en)
    assert_equal %w[8 16 24], definition.attribute_options.where(value: %w[8 16 24]).order(:value).pluck(:value)
  end

  test "merging through the admin endpoint rewrites specs" do
    definition = attribute_definitions(:gpu_chipset)
    source = attribute_options(:chipset_nvidia)
    target = attribute_options(:chipset_amd)

    post admin_attribute_definition_attribute_option_merges_path(definition, locale: :en),
         params: { option_id: source.id, target_id: target.id }

    assert_redirected_to edit_admin_attribute_definition_path(definition, locale: :en)
    assert_equal "amd", listings(:published_gpu).reload.specs["gpu_chipset"]
    assert_not AttributeOption.exists?(source.id)
  end

  test "a definition used by listings cannot be deleted" do
    definition = attribute_definitions(:gpu_chipset)

    assert_no_difference "AttributeDefinition.count" do
      delete admin_attribute_definition_path(definition, locale: :en)
    end

    assert_redirected_to edit_admin_attribute_definition_path(definition, locale: :en)
    assert_equal I18n.t("admin.attribute_definitions.flash.in_use", locale: :en), flash[:alert]
  end

  test "an unused definition can be deleted" do
    definition = AttributeDefinition.create!(
      key: "phase7b_delete_me", name: { es: "Borrar", en: "Delete me" },
      input_type: :text, position: 91
    )

    assert_difference "AttributeDefinition.count", -1 do
      delete admin_attribute_definition_path(definition, locale: :en)
    end
    assert_redirected_to admin_attribute_definitions_path(locale: :en)
  end
end
