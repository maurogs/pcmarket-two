# frozen_string_literal: true

require "yaml"
require "json"
require "fileutils"
require "open3"
require "securerandom"
require "set"
require "pathname"

module Demo
  # Downloads and caches the demo photo library under tmp/demo_images.
  #
  # Layout:
  #   tmp/demo_images/<category>/<provider>-<external-id>.jpg
  #   tmp/demo_images/<category>/manifest.json
  #
  # The manifest is the attribution record used by /credits. Re-running never
  # downloads a file that already exists with a manifest entry.
  class ImageLibrary
    DEFAULT_ROOT = Rails.root.join("tmp/demo_images")
    QUERIES_PATH = Rails.root.join("lib/demo/image_queries.yml")
    DEFAULT_PER_CATEGORY = 12
    PLACEHOLDER_GRADIENTS = [
      [ "#0f172a", "#4338ca" ],
      [ "#1e293b", "#0e7490" ],
      [ "#312e81", "#be123c" ],
      [ "#111827", "#047857" ],
      [ "#3b0764", "#c2410c" ],
      [ "#172554", "#7e22ce" ]
    ].freeze

    attr_reader :root, :logger

    def initialize(root: nil, queries_path: nil, logger: Rails.logger, providers: nil, sleeper: nil)
      @root = Pathname(root || ENV["DEMO_IMAGE_ROOT"] || DEFAULT_ROOT)
      @queries_path = Pathname(queries_path || QUERIES_PATH)
      @logger = logger
      @sleeper = sleeper
      @providers = providers || self.class.default_providers(logger: logger, sleeper: sleeper)
      @manifests = {}
      @disabled_providers = []
      @skipped_logged = []
      @provider_failures = Hash.new(0)
    end

    def self.default_providers(logger: Rails.logger, sleeper: nil)
      [
        Demo::ImageSources::Openverse.new(logger: logger, sleeper: sleeper),
        Demo::ImageSources::Unsplash.new(logger: logger, sleeper: sleeper),
        Demo::ImageSources::Pexels.new(logger: logger, sleeper: sleeper),
        Demo::ImageSources::Pixabay.new(logger: logger, sleeper: sleeper)
      ]
    end

    def categories
      queries.keys
    end

    def queries_for(category_slug)
      Array(queries[category_slug.to_s])
    end

    # Cached entries whose file is still present on disk. Generated placeholders
    # are only returned when no real photo exists, so a later run can replace
    # them without the seed mixing placeholders into a downloaded library.
    def entries_for(category_slug)
      entries = load_manifest(category_slug).select do |entry|
        File.file?(File.join(category_dir(category_slug), entry["file"].to_s))
      end
      real = entries.reject { |entry| entry["provider"] == "placeholder" }
      real.any? ? real : entries
    end

    # Downloads up to `per_category` photos for each requested category.
    # Returns a summary hash.
    def fetch!(categories: nil, per_category: DEFAULT_PER_CATEGORY)
      wanted = Array(categories).presence&.map(&:to_s) || self.categories
      summary = Hash.new(0)

      wanted.each do |slug|
        if queries_for(slug).empty?
          logger&.warn("[demo:images] no queries configured for #{slug}, skipping")
          next
        end

        downloaded = fetch_category(slug, per_category: per_category.to_i)
        summary[slug] = downloaded
      end

      summary
    end

    def fetch_category(category_slug, per_category: DEFAULT_PER_CATEGORY)
      all_entries = load_manifest(category_slug).select do |entry|
        File.file?(File.join(category_dir(category_slug), entry["file"].to_s))
      end
      existing = all_entries.reject { |entry| entry["provider"] == "placeholder" }
      return 0 if existing.size >= per_category

      needed = per_category - existing.size
      known = all_entries.map { |entry| [ entry["provider"], entry["external_id"].to_s ] }.to_set
      candidates = collect_candidates(category_slug, needed, known)
      download_candidates(category_slug, candidates, limit: needed)
    end

    # Search APIs sequentially (they are the rate-limited part). One query
    # usually returns the 20 results needed for a category; extra queries are
    # only used when a provider returns fewer than the requested number.
    def collect_candidates(category_slug, needed, known)
      candidates = []

      providers.each do |provider|
        next if @disabled_providers.include?(provider.provider_name)

        unless provider.available?
          unless @skipped_logged.include?(provider.provider_name)
            logger&.info("[demo:images] skipping #{provider.provider_name}: #{provider.skip_reason}")
            @skipped_logged << provider.provider_name
          end
          next
        end

        break if candidates.size >= needed

        queries_for(category_slug).each do |query|
          break if candidates.size >= needed

          results = begin
            provider.search(query, limit: 20)
          rescue Demo::ImageSources::RateLimited => e
            logger&.warn("[demo:images] #{provider.provider_name} rate limited: #{e.message}; skipping for this run")
            @disabled_providers << provider.provider_name
            break
          rescue Demo::ImageSources::RequestFailed => e
            @provider_failures[provider.provider_name] += 1
            logger&.warn("[demo:images] #{provider.provider_name} search failed for #{query.inspect}: #{e.message}")
            if @provider_failures[provider.provider_name] >= 3
              logger&.warn("[demo:images] #{provider.provider_name} failed three times; skipping it for this run")
              @disabled_providers << provider.provider_name
              break
            end
            next
          end
          @provider_failures[provider.provider_name] = 0

          results.each do |result|
            key = [ result[:provider], result[:external_id].to_s ]
            next if known.include?(key)

            known << key
            candidates << result
            break if candidates.size >= needed
          end
        end
      end

      candidates
    end

    # Downloads run in a small thread pool because most of the wall-clock time
    # is network I/O. The manifest is written by the main thread afterwards.
    def download_candidates(category_slug, candidates, limit:)
      return 0 if candidates.empty?

      queue = Queue.new
      candidates.each { |candidate| queue << candidate }
      records = []
      mutex = Mutex.new

      worker = lambda do
        loop do
          entry = begin
            queue.pop(true)
          rescue ThreadError
            break
          end
          break if mutex.synchronize { records.size >= limit }

          begin
            record = download_entry(category_slug, entry)
            mutex.synchronize { records << record }
          rescue Demo::ImageSources::RequestFailed => e
            logger&.warn("[demo:images] #{entry[:provider]} download failed: #{e.message}")
          end
          break if mutex.synchronize { records.size >= limit }
        end
      end

      workers = Rails.env.test? ? 1 : [ 4, candidates.size ].min
      if workers == 1
        worker.call
      else
        threads = workers.times.map do
          Thread.new do
            worker.call
          ensure
            ActiveRecord::Base.connection_handler.clear_active_connections!
          end
        end
        threads.each(&:join)
      end

      records.each { |record| append_manifest(category_slug, record) }
      records.size
    end

    def download_entry(category_slug, entry)
      filename = "#{entry[:provider]}-#{safe_id(entry[:external_id])}.jpg"
      destination = File.join(category_dir(category_slug), filename)

      unless File.file?(destination)
        provider = providers.find { |candidate| candidate.provider_name == entry[:provider] }
        raise Demo::ImageSources::RequestFailed, "unknown provider #{entry[:provider]}" if provider.blank?

        begin
          provider.download(entry, destination)
        rescue Demo::ImageSources::RequestFailed
          fallback = entry[:fallback_url]
          raise if fallback.blank? || fallback == entry[:download_url]

          provider.download(entry.merge(download_url: fallback), destination)
        end
        provider.track_usage(entry)
      end

      entry.except(:fallback_url, :track_url).merge(file: filename, downloaded_at: Time.current.iso8601).stringify_keys
    end

    # Local fallback used when every provider fails (offline/CI). Generates a
    # gradient card with the category name using ImageMagick.
    def ensure_placeholders(category_slug, count: 4)
      existing = entries_for(category_slug)
      return existing if existing.any?

      label = category_slug.to_s.tr("-", " ").split.map(&:capitalize).join(" ")
      entries = count.times.map do |index|
        filename = "placeholder-#{safe_id(category_slug)}-#{index + 1}.jpg"
        destination = File.join(category_dir(category_slug), filename)
        generate_placeholder(destination, label, index)
        {
          "file" => filename,
          "provider" => "placeholder",
          "external_id" => "#{category_slug}-#{index + 1}",
          "title" => "#{label} placeholder",
          "source_url" => nil,
          "author" => "PCMarket",
          "author_url" => nil,
          "license" => "CC0 1.0",
          "license_url" => "https://creativecommons.org/publicdomain/zero/1.0/",
          "downloaded_at" => Time.current.iso8601
        }
      end

      write_manifest(category_slug, load_manifest(category_slug) + entries)
      entries_for(category_slug)
    end

    # Number of cached images per provider across every category.
    def provider_counts
      counts = Hash.new(0)
      manifest_files.each do |path|
        Array(JSON.parse(File.read(path))).each do |entry|
          counts[entry["provider"].to_s] += 1
        end
      rescue JSON::ParserError
        next
      end
      counts
    end

    # Once a category has real photos, drop the placeholder entries/files left
    # behind by an earlier offline run so manifests and summary counts only
    # mention images that can actually be attached.
    def prune_placeholders!
      manifest_files.each do |path|
        slug = File.basename(File.dirname(path))
        entries = load_manifest(slug)
        next unless entries.any? { |entry| entry["provider"] != "placeholder" }

        placeholders, keep = entries.partition { |entry| entry["provider"] == "placeholder" }
        next if placeholders.empty?

        placeholders.each { |entry| FileUtils.rm_f(File.join(category_dir(slug), entry["file"].to_s)) }
        write_manifest(slug, keep)
      end
    end

    def total_images
      manifest_files.sum do |path|
        Array(JSON.parse(File.read(path))).count do |entry|
          File.file?(File.join(File.dirname(path), entry["file"].to_s))
        end
      rescue JSON::ParserError
        0
      end
    end

    def category_dir(category_slug)
      File.join(root, category_slug.to_s)
    end

    private

    attr_reader :providers

    def queries
      @queries ||= YAML.load_file(@queries_path).to_h do |slug, list|
        [ slug.to_s, Array(list).map(&:to_s) ]
      end
    end

    def safe_id(value)
      value.to_s.gsub(/[^a-zA-Z0-9._-]+/, "-").first(80).presence || SecureRandom.hex(6)
    end

    def manifest_path(category_slug)
      File.join(category_dir(category_slug), "manifest.json")
    end

    def load_manifest(category_slug)
      @manifests[category_slug.to_s] ||= begin
        path = manifest_path(category_slug)
        File.file?(path) ? Array(JSON.parse(File.read(path))) : []
      rescue JSON::ParserError
        []
      end
    end

    def append_manifest(category_slug, record)
      manifest = load_manifest(category_slug)
      manifest.reject! do |entry|
        entry["provider"] == record["provider"] && entry["external_id"] == record["external_id"]
      end
      manifest << record
      write_manifest(category_slug, manifest)
    end

    def write_manifest(category_slug, entries)
      FileUtils.mkdir_p(category_dir(category_slug))
      @manifests[category_slug.to_s] = entries
      File.write(manifest_path(category_slug), JSON.pretty_generate(entries))
    end

    def manifest_files
      Dir[File.join(root, "*", "manifest.json")]
    end

    def generate_placeholder(destination, label, index)
      FileUtils.mkdir_p(File.dirname(destination))
      from, to = PLACEHOLDER_GRADIENTS[index % PLACEHOLDER_GRADIENTS.length]
      font = Demo::Fonts.path
      command = [ "magick", "-size", "1600x1200", "gradient:#{from}-#{to}", "-gravity", "center" ]
      if font
        command.concat([ "-font", font, "-fill", "white", "-pointsize", "96", "-annotate", "+0-60", label,
                         "-pointsize", "38", "-fill", "rgba(255,255,255,0.75)",
                         "-annotate", "+0+60", "PCMarket demo image" ])
      end
      command.concat([ "-quality", "85", "jpg:" + destination ])

      _out, err, status = Open3.capture3(*command)

      return if status.success? && File.size?(destination)

      raise Demo::ImageSources::RequestFailed, "placeholder generation failed: #{err}"
    end
  end
end
