# frozen_string_literal: true

require "test_helper"

class AdminCategoriesTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    sign_in users(:admin)
    Rails.cache.clear
  end

  test "the index renders the tree, listing counts and reorder forms" do
    get admin_categories_path(locale: :en)

    assert_response :success
    assert_includes response.body, categories(:components).name_en
    assert_includes response.body, categories(:gpus).name_en
    assert_includes response.body, I18n.t("admin.categories.table.listings", count: categories(:gpus).listings_count, locale: :en)
    assert_select "form[action='#{admin_category_positions_path(locale: :en)}']", minimum: 1
  end

  test "creates and edits a category with translated fields and an editable slug" do
    post admin_categories_path(locale: :en), params: {
      category: {
        name_es: "Accesorios", name_en: "Accessories", name_fr: "Accessoires",
        description_es: "Accesorios para PC", description_en: "PC accessories",
        seo_title_en: "PC accessories", seo_description_en: "Buy PC accessories",
        slug: "accessories", icon: "keyboard", active: "1", parent_id: categories(:components).id
      }
    }

    assert_redirected_to admin_categories_path(locale: :en)
    category = Category.find_by!(slug: "accessories")
    assert_equal "Accesorios", category.name_es
    assert_equal categories(:components), category.parent

    patch admin_category_path(category, locale: :en), params: {
      category: { slug: "accessories-new", name_en: "Accessories and cables" }
    }

    assert_redirected_to edit_admin_category_path(category.reload, locale: :en)
    category.reload
    assert_equal "accessories-new", category.slug
    assert_equal category, Category.friendly.find("accessories")
  end

  test "reorders siblings and moves a category to another parent" do
    components = categories(:components)
    gpus = categories(:gpus)
    cpus = categories(:cpus)
    nvidia = categories(:nvidia)

    patch admin_category_positions_path(locale: :en), params: {
      parent_id: components.id,
      ordered_ids: [ cpus.id, gpus.id ],
      moves: { nvidia.id => components.id }
    }

    assert_redirected_to admin_categories_path(locale: :en)
    assert_equal 1, cpus.reload.position
    assert_equal 2, gpus.reload.position
    assert_equal components, nvidia.reload.parent
  end

  test "moving a category under its own descendant is rejected without changes" do
    components = categories(:components)
    nvidia = categories(:nvidia)

    patch admin_category_positions_path(locale: :en), params: {
      parent_id: components.id,
      ordered_ids: [ categories(:gpus).id ],
      moves: { components.id => nvidia.id }
    }

    assert_response :redirect
    assert_includes flash[:alert], I18n.t("categories.errors.cycle", locale: :en)
    assert_nil components.reload.parent
  end

  test "deleting requires an empty category" do
    gpus = categories(:gpus)

    assert_no_difference "Category.count" do
      delete admin_category_path(gpus, locale: :en)
    end
    assert_response :redirect
    assert_includes flash[:alert], I18n.t("admin.categories.flash.not_empty", locale: :en, listings: gpus.listings.count, children: gpus.children.count)

    empty = Category.create!(name: "Empty", slug: "empty-category", active: true)
    assert_difference "Category.count", -1 do
      delete admin_category_path(empty, locale: :en)
    end
    assert_redirected_to admin_categories_path(locale: :en)
  end

  test "deactivating a category hides its listings from browsing" do
    gpus = categories(:gpus)
    listing = listings(:published_gpu)
    assert_includes Listing.visible, listing

    patch admin_category_path(gpus, locale: :en), params: { category: { active: "0" } }

    assert_redirected_to edit_admin_category_path(gpus, locale: :en)
    refute_predicate gpus.reload, :active?
    assert_not_includes Listing.visible, listing
  end
end
