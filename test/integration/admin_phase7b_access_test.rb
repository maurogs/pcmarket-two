# frozen_string_literal: true

require "test_helper"

class AdminPhase7bAccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @moderator = users(:moderator)
  end

  test "an administrator can open every catalogue and configuration screen" do
    sign_in @admin

    paths = [
      admin_categories_path(locale: :en),
      new_admin_category_path(locale: :en),
      edit_admin_category_path(categories(:gpus), locale: :en),
      admin_category_category_attributes_path(categories(:gpus), locale: :en),
      admin_attribute_definitions_path(locale: :en),
      new_admin_attribute_definition_path(locale: :en),
      edit_admin_attribute_definition_path(attribute_definitions(:gpu_chipset), locale: :en),
      admin_tags_path(locale: :en),
      new_admin_tag_path(locale: :en),
      edit_admin_tag_path(tags(:featured), locale: :en),
      admin_countries_path(locale: :en),
      edit_admin_country_path(countries(:france), locale: :en),
      admin_country_regions_path(countries(:france), locale: :en),
      admin_settings_path(locale: :en),
      admin_features_path(locale: :en),
      admin_legal_pages_path(locale: :en),
      new_admin_legal_page_path(locale: :en)
    ]

    paths.each do |path|
      get path, params: { locale: :en }
      assert_response :success, "Expected #{path} to render"
    end
  end

  test "moderators get a 404 on every Phase 7b section" do
    sign_in @moderator

    [
      admin_categories_path(locale: :en),
      edit_admin_category_path(categories(:gpus), locale: :en),
      admin_category_category_attributes_path(categories(:gpus), locale: :en),
      admin_attribute_definitions_path(locale: :en),
      edit_admin_attribute_definition_path(attribute_definitions(:gpu_chipset), locale: :en),
      admin_tags_path(locale: :en),
      edit_admin_tag_path(tags(:featured), locale: :en),
      admin_countries_path(locale: :en),
      edit_admin_country_path(countries(:france), locale: :en),
      admin_country_regions_path(countries(:france), locale: :en),
      admin_settings_path(locale: :en),
      admin_features_path(locale: :en),
      admin_legal_pages_path(locale: :en),
      new_admin_legal_page_path(locale: :en)
    ].each do |path|
      get path
      assert_response :not_found, "Expected #{path} to be hidden from moderators"
    end
  end

  test "moderators cannot mutate catalogue records" do
    sign_in @moderator

    patch admin_category_path(categories(:gpus), locale: :en), params: { category: { active: false } }
    assert_response :not_found

    patch admin_settings_path(locale: :en), params: { settings: { commission_percent: "10" } }
    assert_response :not_found

    post admin_impersonation_path(locale: :en), params: { user_id: users(:confirmed).id }
    assert_response :not_found

    patch admin_category_positions_path(locale: :en), params: { ordered_ids: [] }
    assert_response :not_found

    patch admin_tag_positions_path(locale: :en), params: { ordered_ids: [] }
    assert_response :not_found

    patch admin_country_path(countries(:france), locale: :en), params: { country: { active: "1" } }
    assert_response :not_found

    post admin_attribute_definition_attribute_option_merges_path(attribute_definitions(:gpu_chipset), locale: :en)
    assert_response :not_found

    post admin_attribute_definition_attribute_option_import_path(attribute_definitions(:gpu_chipset), locale: :en)
    assert_response :not_found

    patch admin_feature_path("offers", locale: :en), params: { enabled: "1" }
    assert_response :not_found
  end
end
