# frozen_string_literal: true

module Listings
  # Resolves the GPU and CPU performance tiers from the listing specs. The
  # table matches free-text model names case-insensitively so sellers can type
  # "RTX 4070 Ti Super" or "NVIDIA GeForce RTX 4070 ti super".
  class PerformanceTier
    def initialize(listing)
      @listing = listing
    end

    def gpu_tier
      GpuTier.tier_for(spec("gpu_model")) || 0
    end

    def cpu_tier
      CpuTier.tier_for(spec("cpu_model")) || 0
    end

    def call
      @listing.gpu_tier = gpu_tier
      @listing.cpu_tier = cpu_tier
      @listing
    end

    private

    def spec(key)
      return if @listing.specs.blank?

      @listing.specs[key] || @listing.specs[key.to_sym]
    end
  end
end
