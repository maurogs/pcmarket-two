# frozen_string_literal: true

namespace :pcmarket do
  desc "Recompute gpu_tier/cpu_tier for every listing from its specs"
  task compute_tiers: :environment do
    updated = 0

    Listing.find_each do |listing|
      before = [ listing.gpu_tier, listing.cpu_tier ]
      Listings::PerformanceTier.new(listing).call
      next if before == [ listing.gpu_tier, listing.cpu_tier ]

      listing.save!(validate: false)
      updated += 1
    end

    puts "Computed performance tiers for #{updated} listing(s)."
  end
end
