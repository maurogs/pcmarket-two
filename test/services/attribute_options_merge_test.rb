# frozen_string_literal: true

require "test_helper"

class AttributeOptionsMergeTest < ActiveSupport::TestCase
  test "merging rewrites scalar specs to the target value and deletes the source" do
    source = attribute_options(:chipset_nvidia)
    target = attribute_options(:chipset_amd)
    listing = listings(:published_gpu)
    assert_equal "nvidia", listing.specs["gpu_chipset"]

    updated = AttributeOptions::Merge.new(option: source, target: target).call

    assert_operator updated, :>=, 1
    assert_equal "amd", listing.reload.specs["gpu_chipset"]
    assert_not AttributeOption.exists?(source.id)
    assert AttributeOption.exists?(target.id)
  end

  test "merging rewrites arrays, removes duplicates and keeps other values" do
    source = attribute_options(:memory_gddr6)
    target = attribute_options(:memory_gddr6x)
    listing = create_listing!(
      store: stores(:confirmed_store), seller: users(:confirmed),
      title: "Dual memory listing", specs: { gpu_memory_type: %w[gddr6 gddr6x] }
    )

    AttributeOptions::Merge.new(option: source, target: target).call
    listing.reload

    assert_equal %w[gddr6x], listing.specs["gpu_memory_type"]
    assert_empty Listing.where("specs @> ?::jsonb", { gpu_memory_type: [ "gddr6" ] }.to_json)
  end

  test "merging options from different definitions is rejected" do
    source = attribute_options(:chipset_nvidia)
    target = attribute_options(:memory_gddr6)

    assert_raises(ArgumentError) do
      AttributeOptions::Merge.new(option: source, target: target).call
    end
  end
end
