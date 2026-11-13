# frozen_string_literal: true

require "test_helper"

class CatalogueSeedsTest < ActiveSupport::TestCase
  setup do
    ListingPhoto.delete_all
    ListingModeration.delete_all
    ListingTag.delete_all
    Listing.delete_all
    CategoryAttribute.delete_all
    AttributeOption.delete_all
    AttributeDefinition.delete_all
    Tag.delete_all
    Category.delete_all

    Rails.cache.clear
    load_catalogue_seeds
  end

  test "seeds the category tree" do
    assert_equal 10, Category.roots.count
    assert_operator Category.count, :>, 50
    assert_equal 1, Category.find_by!(slug: "gaming-pcs").position
    assert_equal "gaming-pcs", Category.find_by!(slug: "gaming-pcs").slug
  end

  test "seeds the attribute catalogue and tags" do
    assert_operator AttributeDefinition.count, :>=, 45
    assert_operator Tag.count, :>=, 30
    assert_equal 13, Tag.where(kind: :product_label).count
    assert_equal 21, Tag.where(kind: :seller_tag).count
    assert_predicate AttributeDefinition.find_by!(key: "gpu_chipset"), :filterable?

    lt_one = AttributeDefinition.find_by!(key: "gpu_memory")
      .attribute_options.find_by!(value: "lt_1")
    assert_equal "<1", lt_one.label_en
    refute_predicate lt_one, :popular?
    assert AttributeDefinition.find_by!(key: "memory_capacity")
      .attribute_options.exists?(value: "less_than_8")
  end

  test "loading the seeds twice does not create duplicates" do
    counts = {
      categories: Category.count,
      attribute_definitions: AttributeDefinition.count,
      attribute_options: AttributeOption.count,
      category_attributes: CategoryAttribute.count,
      tags: Tag.count
    }

    load_catalogue_seeds

    assert_equal counts[:categories], Category.count
    assert_equal counts[:attribute_definitions], AttributeDefinition.count
    assert_equal counts[:attribute_options], AttributeOption.count
    assert_equal counts[:category_attributes], CategoryAttribute.count
    assert_equal counts[:tags], Tag.count
    assert_equal Category.count, Category.distinct.count(:slug)
  end

  test "every translated field has the six locales" do
    Category.find_each do |category|
      %i[name description seo_title seo_description].each do |field|
        assert_translated category, field, "category #{category.slug}"
      end
    end

    AttributeDefinition.find_each do |definition|
      assert_translated definition, :name, "attribute #{definition.key}"
    end

    AttributeOption.includes(:attribute_definition).find_each do |option|
      assert_translated option, :label, "option #{option.attribute_definition.key}/#{option.value}"
    end

    Tag.find_each do |tag|
      assert_translated tag, :name, "tag #{tag.slug}"
    end
  end

  test "gaming pcs inherit a required gpu chipset attribute" do
    category = Category.find_by!(slug: "gaming-pcs")
    definitions = category.effective_attribute_definitions

    assert_includes definitions.map(&:key), "gpu_chipset"

    link = category.effective_category_attributes.find do |category_attribute|
      category_attribute.attribute_definition.key == "gpu_chipset"
    end
    assert_predicate link, :required?
  end

  test "physical leaves receive warranty and box attributes" do
    keepers = %w[warranty_months includes_original_box]

    assert_equal keepers.sort,
                 Category.find_by!(slug: "collectibles").category_attributes
                   .joins(:attribute_definition)
                   .where(attribute_definitions: { key: keepers })
                   .pluck("attribute_definitions.key").sort
    assert_empty Category.find_by!(slug: "games").category_attributes
      .joins(:attribute_definition)
      .where(attribute_definitions: { key: keepers })
  end

  private

  def load_catalogue_seeds
    load Rails.root.join("db/seeds/categories.rb")
    load Rails.root.join("db/seeds/attributes.rb")
    load Rails.root.join("db/seeds/tags.rb")
  end

  def assert_translated(record, field, label)
    translations = record.read_attribute(field)
    translations = JSON.parse(translations) if translations.is_a?(String)

    %w[es en fr de it pt].each do |locale|
      value = translations[locale]
      assert value.is_a?(String) && value.strip.present?,
             "#{label} is missing a #{locale} translation for #{field}: #{translations.inspect}"
    end
  end
end
