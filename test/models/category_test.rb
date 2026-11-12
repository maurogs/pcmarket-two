# frozen_string_literal: true

require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "roots returns only top-level categories ordered by position" do
    assert_equal [ categories(:components) ], Category.roots.to_a
  end

  test "root? is true only for categories without a parent" do
    assert categories(:components).root?
    assert_not categories(:gpus).root?
  end

  test "descendant_ids includes self and every descendant" do
    root = categories(:components)

    assert_equal [ root.id, categories(:gpus).id, categories(:cpus).id,
                   categories(:nvidia).id ].sort,
                 root.descendant_ids.sort

    assert_equal [ categories(:gpus).id, categories(:nvidia).id ].sort,
                 categories(:gpus).descendant_ids.sort
  end

  test "descendant_ids is cached and invalidated after any category update" do
    store = ActiveSupport::Cache::MemoryStore.new

    with_cache(store) do
      gpus = categories(:gpus)
      assert_equal [ gpus.id, categories(:nvidia).id ].sort,
                   gpus.descendant_ids.sort

      categories(:nvidia).update!(parent: categories(:components))

      assert_equal [ gpus.id ], gpus.descendant_ids
    end
  end

  test "ancestors are returned root first" do
    assert_equal [ categories(:components), categories(:gpus) ],
                 categories(:nvidia).ancestors
  end

  test "breadcrumb includes the ancestors and the category itself" do
    assert_equal [ categories(:components), categories(:gpus), categories(:nvidia) ],
                 categories(:nvidia).breadcrumb
  end

  test "depth is derived from the parent automatically" do
    child = Category.create!(name_en: "Water Cooling", parent: categories(:nvidia))

    assert_equal 3, child.depth
    assert_equal 0, categories(:components).depth
  end

  test "reparenting refreshes the depths of descendants" do
    categories(:gpus).update!(parent: nil)

    assert_equal 0, categories(:gpus).reload.depth
    assert_equal 1, categories(:nvidia).reload.depth
  end

  test "a category cannot be its own parent" do
    gpus = categories(:gpus)
    gpus.parent = gpus

    assert_not gpus.valid?
    assert gpus.errors[:parent_id].any?
  end

  test "a category cannot be parented to one of its descendants" do
    gpus = categories(:gpus)
    gpus.parent = categories(:nvidia)

    assert_not gpus.valid?
    assert gpus.errors[:parent_id].any?
  end

  test "slug is generated from the English name" do
    category = Category.create!(name_en: "Cooling Fans", name_es: "Ventiladores")

    assert_equal "cooling-fans", category.slug
  end

  test "translated names fall back to English then Spanish" do
    category = Category.create!(name_en: "Cases", name_es: "Cajas")

    I18n.with_locale(:fr) do
      assert_equal "Cases", category.name
    end
  end

  test "effective_attribute_definitions inherits ancestors, de-duplicates and orders by position" do
    definitions = categories(:nvidia).effective_attribute_definitions

    assert_equal %w[gpu_chipset gpu_memory_type warranty], definitions.map(&:key)
    assert_equal definitions.map(&:id).uniq.size, definitions.size
  end

  test "effective_attribute_definitions eager loads the options" do
    definitions = categories(:nvidia).effective_attribute_definitions

    assert definitions.all? { |definition| definition.association(:attribute_options).loaded? }
  end

  test "required definitions are available through the category attribute links" do
    assert categories(:gpus).effective_category_attributes.any?(&:required?)
  end
end
