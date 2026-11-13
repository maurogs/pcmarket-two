# frozen_string_literal: true

require "test_helper"

class PerformanceTierTest < ActiveSupport::TestCase
  test "matches the longest GPU pattern case-insensitively" do
    GpuTier.create!(pattern: "rtx 4070", tier: 7, position: 1)
    GpuTier.create!(pattern: "rtx 4070 ti", tier: 8, position: 2)

    assert_equal 8, GpuTier.tier_for("NVIDIA GeForce RTX 4070 Ti Super")
    assert_equal 7, GpuTier.tier_for("rtx 4070")
    assert_nil GpuTier.tier_for("GTX 1080")
  end

  test "computes tiers from listing specs on save" do
    GpuTier.create!(pattern: "rtx 4060", tier: 6)
    CpuTier.create!(pattern: "ryzen 5 5", tier: 5)

    listing = create_listing!(
      store: stores(:confirmed_store), seller: users(:confirmed),
      specs: { "gpu_model" => "NVIDIA GeForce RTX 4060", "cpu_model" => "AMD Ryzen 5 5600X" }
    )

    assert_equal 6, listing.gpu_tier
    assert_equal 5, listing.cpu_tier

    listing.update!(specs: { "gpu_model" => "RTX 4090", "cpu_model" => "Ryzen 9 7900X" })
    assert_equal 0, listing.reload.gpu_tier
    assert_equal 0, listing.cpu_tier
  end

  test "matches common Intel and AMD CPU model strings" do
    CpuTier.create!(pattern: "i5-12", tier: 5)
    CpuTier.create!(pattern: "core ultra 7", tier: 7)
    CpuTier.create!(pattern: "ryzen 7 7", tier: 7)

    assert_equal 5, CpuTier.tier_for("Intel Core i5-12400F")
    assert_equal 5, CpuTier.tier_for("Intel Core i5 12400F")
    assert_equal 7, CpuTier.tier_for("Intel Core Ultra 7 265K")
    assert_equal 7, CpuTier.tier_for("AMD Ryzen 7 7800X3D")
  end

  test "inactive patterns are ignored" do
    GpuTier.create!(pattern: "rtx 4080", tier: 9, active: false)

    assert_nil GpuTier.tier_for("RTX 4080")
  end
end
