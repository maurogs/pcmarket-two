# frozen_string_literal: true

require "test_helper"

class TranslatableFieldsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "the category form renders six tabbed inputs per translated field" do
    get new_admin_category_path(locale: :en)

    assert_response :success

    assert_select "input[name='category[name_es]'][required]", 1
    assert_select "input[name='category[name_en]']:not([required])", 1
    assert_select "input[name='category[name_fr]']", 1
    assert_select "input[name='category[name_de]']", 1
    assert_select "input[name='category[name_it]']", 1
    assert_select "input[name='category[name_pt]']", 1

    assert_select "textarea[name='category[description_es]']", 1
    assert_select "textarea[name='category[description_en]']", 1

    assert_select "button[role='tab'][data-locale='es'][aria-selected='true']", 4
    assert_select "button[role='tab'][data-locale='en'][aria-selected='false']", 4
  end

  test "empty locales show a missing dot while filled locales show a success dot" do
    I18n.with_locale(:en) do
      category = categories(:gpus)
      get edit_admin_category_path(category, locale: :en)
      assert_response :success

      assert_select "button[data-locale='es'] span.bg-success", minimum: 1
      assert_select "button[data-locale='fr'] span.bg-danger", minimum: 1
    end
  end
end
