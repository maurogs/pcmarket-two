# frozen_string_literal: true

require "test_helper"

class AdminCategoryAttributesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "the filter screen lists own and inherited attributes" do
    get admin_category_category_attributes_path(categories(:gpus), locale: :en)

    assert_response :success
    assert_includes response.body, attribute_definitions(:gpu_chipset).name_en
    assert_includes response.body, attribute_definitions(:warranty).name_en
    assert_includes response.body, I18n.t("admin.category_attributes.sources.inherited_from",
                                          category: categories(:components).name_en, locale: :en)
  end

  test "attaches, toggles required, reorders and removes an own filter" do
    category = categories(:cpus)
    definition = attribute_definitions(:gpu_chipset)

    assert_difference "CategoryAttribute.count", 1 do
      post admin_category_category_attributes_path(category, locale: :en),
           params: { attribute_definition_id: definition.id }
    end
    row = category.category_attributes.find_by!(attribute_definition: definition)
    assert_redirected_to admin_category_category_attributes_path(category, locale: :en)

    patch admin_category_category_attribute_path(category, row, locale: :en),
          params: { category_attribute: { required: "1", position: 3 } }

    assert_predicate row.reload, :required?
    assert_equal 3, row.position

    other = CategoryAttribute.create!(category: category, attribute_definition: attribute_definitions(:gpu_memory_type), position: 4)
    patch admin_category_category_attribute_positions_path(category, locale: :en),
          params: { ordered_ids: [ other.id, row.id ] }

    assert_equal 1, other.reload.position
    assert_equal 2, row.reload.position

    assert_difference "CategoryAttribute.count", -1 do
      delete admin_category_category_attribute_path(category, row, locale: :en)
    end
    assert_redirected_to admin_category_category_attributes_path(category, locale: :en)
  end

  test "inherited rows cannot be removed from the child category" do
    inherited = category_attributes(:components_warranty)
    gpus = categories(:gpus)

    assert_no_difference "CategoryAttribute.count" do
      delete admin_category_category_attribute_path(gpus, inherited, locale: :en)
    end

    assert_redirected_to admin_category_category_attributes_path(gpus, locale: :en)
    assert_equal I18n.t("admin.category_attributes.flash.inherited", locale: :en), flash[:alert]
  end
end
