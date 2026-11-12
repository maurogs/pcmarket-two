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

  namespace :demo do
    desc "Download demo photos from Openverse/Unsplash/Pexels/Pixabay (args: categories, per_category)"
    task :images, [ :categories, :per_category ] => :environment do |_task, args|
      raw_categories = args[:categories].presence || ENV["CATEGORIES"]
      categories = raw_categories.to_s.split(",").map(&:strip).reject(&:empty?)
      categories = nil if categories.empty? || categories.include?("all")
      raw_per_category = args[:per_category].presence || ENV["PER_CATEGORY"]
      per_category = (raw_per_category.presence || Demo::ImageLibrary::DEFAULT_PER_CATEGORY).to_i

      library = Demo::ImageLibrary.new
      puts "[demo:images] fetching up to #{per_category} images for " \
           "#{categories&.size || library.categories.size} category(ies) into #{library.root}"

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      summary = library.fetch!(categories: categories, per_category: per_category)

      # Network failures must not leave a category without images: generate the
      # same ImageMagick placeholders the seed would use.
      targets = categories || library.categories
      targets.each do |slug|
        next if library.entries_for(slug).any?

        entries = library.ensure_placeholders(slug, count: 4)
        summary[slug] ||= 0
        puts format("[demo:images]   %-24s generated %d placeholder(s)", slug, entries.size)
      rescue Demo::ImageSources::RequestFailed => e
        warn "[demo:images] #{slug}: placeholder generation failed: #{e.message}"
      end

      library.prune_placeholders!
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

      summary.each do |slug, count|
        puts format("[demo:images]   %-24s +%d (cached: %d)", slug, count, library.entries_for(slug).size)
      end
      puts "[demo:images] #{library.total_images} image(s) available in #{format('%.1f', elapsed)}s " \
           "(#{library.provider_counts.sort.map { |provider, count| "#{provider}=#{count}" }.join(', ')})"
      puts "[demo:images] Categories without network images will get generated placeholders during seeding."
    end

    desc "Create realistic demo users, stores, listings, activity and orders (ENV: DEMO_SCALE, DEMO_PASSWORD)"
    task seed: :environment do
      Demo::Seed.new.call
    end

    desc "Remove every demo-tagged user, store, listing and their activity"
    task reset: :environment do
      removed = Demo::Reset.new.call
      if removed.values.sum.zero?
        puts "[demo:reset] no demo data found"
      else
        removed.reject { |_key, value| value.zero? }.each do |key, value|
          puts format("[demo:reset]   %-20s %d", key, value)
        end
      end
    end
  end
end
