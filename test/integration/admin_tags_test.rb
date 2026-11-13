# frozen_string_literal: true

require "test_helper"

class AdminTagsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "the index shows both kinds with usage counts and colour previews" do
    ListingTag.create!(listing: listings(:published_gpu), tag: tags(:featured))

    get admin_tags_path(locale: :en)

    assert_response :success
    assert_includes response.body, tags(:featured).name_en
    assert_includes response.body, tags(:verified_seller).name_en
    assert_includes response.body, I18n.t("admin.tags.table.listings", count: 1, locale: :en)
    assert_includes response.body, "bg-accent/10"
  end

  test "creates, edits and deactivates a translated tag" do
    post admin_tags_path(locale: :en), params: {
      tag: { kind: "seller_tag", name_es: "Envío rápido", name_en: "Fast shipping",
             colour: "warning", active: "1", position: 10 }
    }

    tag = Tag.find_by!(slug: "fast-shipping")
    assert_redirected_to admin_tags_path(locale: :en)
    assert_equal "Envío rápido", tag.name_es

    patch admin_tag_path(tag, locale: :en), params: {
      tag: { name_en: "Very fast shipping", colour: "success", active: "0", position: 3 }
    }

    assert_redirected_to admin_tags_path(locale: :en)
    tag.reload
    assert_equal "Very fast shipping", tag.name_en
    assert_equal "success", tag.colour
    refute_predicate tag, :active?
    assert_predicate tag, :seller_tag?
  end

  test "reorders tags" do
    first = tags(:featured)
    second = tags(:verified_seller)

    patch admin_tag_positions_path(locale: :en), params: { ordered_ids: [ second.id, first.id ] }

    assert_redirected_to admin_tags_path(locale: :en)
    assert_equal 1, second.reload.position
    assert_equal 2, first.reload.position
  end

  test "a tag used by a listing cannot be deleted" do
    tag = tags(:featured)
    ListingTag.create!(listing: listings(:published_gpu), tag: tag)

    assert_no_difference "Tag.count" do
      delete admin_tag_path(tag, locale: :en)
    end

    assert_redirected_to admin_tags_path(locale: :en)
    assert_equal I18n.t("admin.tags.flash.in_use", locale: :en), flash[:alert]
  end
end
