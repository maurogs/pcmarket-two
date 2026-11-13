# frozen_string_literal: true

require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "slug is generated from the English name" do
    tag = Tag.create!(name_en: "Limited Edition", name_es: "Edición limitada",
                      kind: :product_label)

    assert_equal "limited-edition", tag.slug
  end

  test "slug is unique per kind" do
    Tag.create!(name_en: "Promo", kind: :product_label, slug: "promo")

    duplicate = Tag.new(name_en: "Another promo", kind: :product_label,
                        slug: "promo")
    assert_not duplicate.valid?

    other_kind = Tag.create!(name_en: "Promo seller", kind: :seller_tag,
                             slug: "promo")
    assert other_kind.valid?
  end

  test "kinds are exposed as enum predicates" do
    assert tags(:featured).product_label?
    assert tags(:verified_seller).seller_tag?
  end
end
