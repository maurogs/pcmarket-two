# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "open3"

class DemoImageLibraryTest < ActiveSupport::TestCase
  setup do
    @root = Dir.mktmpdir("demo-images-test")
    @image_path = File.join(@root, "source.jpg")
    _out, _err, status = Open3.capture3("magick", "-size", "900x600", "gradient:#4338ca-#be123c", @image_path)
    skip "ImageMagick is required for demo image tests" unless status.success?

    @image_bytes = File.binread(@image_path)
  end

  teardown do
    FileUtils.rm_rf(@root)
  end

  test "openverse downloads, resizes and records attribution" do
    stub_request(:get, /api\.openverse\.org\/v1\/images\/\?/).to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        results: [ {
          id: "ov-1",
          title: "Graphics card",
          url: "https://originals.example.com/gpu.jpg",
          thumbnail: "https://api.openverse.org/v1/images/ov-1/thumb/",
          foreign_landing_url: "https://example.com/photos/ov-1",
          creator: "Ada Lovelace",
          creator_url: "https://example.com/ada",
          license: "by",
          license_version: "4.0",
          width: 1200,
          height: 900
        } ]
      }.to_json
    )
    stub_request(:get, "https://api.openverse.org/v1/images/ov-1/thumb/")
      .to_return(status: 200, headers: { "Content-Type" => "image/jpeg" }, body: @image_bytes)

    library = build_library([ openverse ])
    assert_equal 1, library.fetch_category("gpus", per_category: 1)

    entries = library.entries_for("gpus")
    assert_equal 1, entries.size
    entry = entries.first
    assert_equal "openverse", entry["provider"]
    assert_equal "Ada Lovelace", entry["author"]
    assert_equal "BY 4.0", entry["license"]
    assert_equal "https://example.com/photos/ov-1", entry["source_url"]
    assert File.file?(File.join(library.category_dir("gpus"), entry["file"]))

    _out, _err, identify = Open3.capture3("magick", "identify", "-format", "%w", File.join(library.category_dir("gpus"), entry["file"]))
    assert_operator identify.to_i, :<=, 1600

    assert_requested :get, /api\.openverse\.org\/v1\/images\/\?/, times: 1
    assert_requested :get, "https://api.openverse.org/v1/images/ov-1/thumb/", times: 1
  end

  test "openverse falls back to the original url when the thumbnail fails" do
    stub_request(:get, /api\.openverse\.org\/v1\/images\/\?/).to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        results: [ {
          id: "ov-2", title: "GPU", url: "https://originals.example.com/gpu-2.jpg",
          thumbnail: "https://api.openverse.org/v1/images/ov-2/thumb/",
          foreign_landing_url: "https://example.com/photos/ov-2",
          creator: "Grace Hopper", license: "cc0", license_version: "1.0"
        } ]
      }.to_json
    )
    stub_request(:get, "https://api.openverse.org/v1/images/ov-2/thumb/").to_return(status: 403)
    stub_request(:get, "https://originals.example.com/gpu-2.jpg")
      .to_return(status: 200, headers: { "Content-Type" => "image/jpeg" }, body: @image_bytes)

    library = build_library([ openverse ])
    assert_equal 1, library.fetch_category("gpus", per_category: 1)
    assert_equal 1, library.entries_for("gpus").size
  end

  test "cached images are never downloaded again" do
    stub_openverse_result("ov-cached")
    library = build_library([ openverse ])

    library.fetch_category("gpus", per_category: 1)
    first_mtime = File.mtime(File.join(library.category_dir("gpus"), library.entries_for("gpus").first["file"]))

    assert_equal 0, library.fetch_category("gpus", per_category: 1)
    assert_equal first_mtime, File.mtime(File.join(library.category_dir("gpus"), library.entries_for("gpus").first["file"]))
    assert_requested :get, /api\.openverse\.org\/v1\/images\/\?/, times: 1
  end

  test "providers without an api key are skipped" do
    names = {
      Demo::ImageSources::Unsplash.new => "UNSPLASH_ACCESS_KEY",
      Demo::ImageSources::Pexels.new => "PEXELS_API_KEY",
      Demo::ImageSources::Pixabay.new => "PIXABAY_API_KEY"
    }

    names.each do |provider, env_key|
      with_env(env_key => nil) do
        refute provider.available?, "#{provider.provider_name} should be skipped without #{env_key}"
        assert_includes provider.skip_reason, env_key
      end
    end

    with_env("UNSPLASH_ACCESS_KEY" => nil, "PEXELS_API_KEY" => nil, "PIXABAY_API_KEY" => nil) do
      providers = [
        Demo::ImageSources::Unsplash.new(sleeper: ->(_seconds) { }, request_interval: 0),
        Demo::ImageSources::Pexels.new(sleeper: ->(_seconds) { }, request_interval: 0),
        Demo::ImageSources::Pixabay.new(sleeper: ->(_seconds) { }, request_interval: 0)
      ]
      library = build_library(providers)
      assert_equal 0, library.fetch_category("gpus", per_category: 1)
    end
  end

  test "unsplash triggers the download endpoint and credits the photographer" do
    with_env("UNSPLASH_ACCESS_KEY" => "test-key") do
      stub_request(:get, /api\.unsplash\.com\/search\/photos/)
        .with(headers: { "Authorization" => "Client-ID test-key" })
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: {
            results: [ {
              id: "us-1",
              alt_description: "Graphics card on a desk",
              width: 1600,
              height: 1000,
              links: {
                html: "https://unsplash.com/photos/us-1",
                download_location: "https://api.unsplash.com/photos/us-1/download"
              },
              urls: { full: "https://images.unsplash.com/photo-us-1.jpg" },
              user: { name: "John Doe", username: "jdoe", links: { html: "https://unsplash.com/@jdoe" } }
            } ]
          }.to_json
        )
      stub_request(:get, "https://images.unsplash.com/photo-us-1.jpg")
        .to_return(status: 200, headers: { "Content-Type" => "image/jpeg" }, body: @image_bytes)
      stub_request(:get, "https://api.unsplash.com/photos/us-1/download")
        .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: "{}")

      library = build_library([ Demo::ImageSources::Unsplash.new(sleeper: ->(_seconds) { }, request_interval: 0) ])
      assert_equal 1, library.fetch_category("gpus", per_category: 1)

      entry = library.entries_for("gpus").first
      assert_equal "unsplash", entry["provider"]
      assert_equal "John Doe", entry["author"]
      assert_includes entry["author_url"], "utm_source=pcmarket_demo"
      assert_equal "Unsplash License", entry["license"]
      assert_requested :get, "https://api.unsplash.com/photos/us-1/download", times: 1
    end
  end

  test "pexels and pixabay map their attribution fields" do
    pexels = Demo::ImageSources::Pexels.new(sleeper: ->(_seconds) { }, request_interval: 0)
    pixabay = Demo::ImageSources::Pixabay.new(sleeper: ->(_seconds) { }, request_interval: 0)

    with_env("PEXELS_API_KEY" => "pexels-key") do
      stub_request(:get, /api\.pexels\.com\/v1\/search/)
        .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                   body: { photos: [ {
                     id: 10, alt: "PC case", url: "https://www.pexels.com/photo/10/",
                     photographer: "Pexels Person", photographer_url: "https://www.pexels.com/@person",
                     width: 1200, height: 800,
                     src: { large2x: "https://images.pexels.com/photos/10/large.jpg" }
                   } ] }.to_json)
      result = pexels.search("pc case").first
      assert_equal "pexels", result[:provider]
      assert_equal "Pexels Person", result[:author]
      assert_equal "Pexels License", result[:license]
      assert_equal "https://www.pexels.com/photo/10/", result[:source_url]
    end

    with_env("PIXABAY_API_KEY" => "pixabay-key") do
      stub_request(:get, /pixabay\.com\/api/)
        .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                   body: { hits: [ {
                     id: 20, tags: "computer, hardware", user: "Pix Person", user_id: 123,
                     pageURL: "https://pixabay.com/photos/20/",
                     largeImageURL: "https://pixabay.com/get/20.jpg",
                     imageWidth: 1920, imageHeight: 1080
                   } ] }.to_json)
      result = pixabay.search("computer").first
      assert_equal "pixabay", result[:provider]
      assert_equal "Pix Person", result[:author]
      assert_equal "Pixabay Content License", result[:license]
      assert_equal "https://pixabay.com/photos/20/", result[:source_url]
    end
  end

  test "generates placeholder images when no provider returns anything" do
    library = build_library([])

    entries = library.ensure_placeholders("gpus", count: 2)
    assert_equal 2, entries.size
    entries.each do |entry|
      assert_equal "placeholder", entry["provider"]
      assert_equal "PCMarket", entry["author"]
      assert_equal "CC0 1.0", entry["license"]
      assert File.file?(File.join(library.category_dir("gpus"), entry["file"]))
    end

    assert_equal entries, library.entries_for("gpus")
    assert_equal 0, library.fetch_category("gpus", per_category: 2)
  end

  test "openverse retries a 429 before succeeding" do
    delays = []
    provider = Demo::ImageSources::Openverse.new(
      logger: Logger.new(nil),
      sleeper: ->(seconds) { delays << seconds },
      request_interval: 0
    )

    stub_request(:get, /api\.openverse\.org\/v1\/images\/\?/)
      .to_return(
        { status: 429, headers: { "Retry-After" => "3" } },
        { status: 200, headers: { "Content-Type" => "application/json" }, body: { results: [] }.to_json }
      )

    assert_equal [], provider.search("gpus")
    assert_includes delays, 3
    assert_requested :get, /api\.openverse\.org\/v1\/images\/\?/, times: 2
  end

  private

  def openverse
    Demo::ImageSources::Openverse.new(sleeper: ->(_seconds) { }, request_interval: 0, logger: Logger.new(nil))
  end

  def build_library(providers)
    Demo::ImageLibrary.new(
      root: @root,
      providers: providers,
      sleeper: ->(_seconds) { },
      logger: Logger.new(nil)
    )
  end

  def stub_openverse_result(id)
    stub_request(:get, /api\.openverse\.org\/v1\/images\/\?/).to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        results: [ {
          id: id, title: "GPU", url: "https://originals.example.com/#{id}.jpg",
          thumbnail: "https://api.openverse.org/v1/images/#{id}/thumb/",
          foreign_landing_url: "https://example.com/photos/#{id}",
          creator: "Tester", license: "by", license_version: "4.0"
        } ]
      }.to_json
    )
    stub_request(:get, "https://api.openverse.org/v1/images/#{id}/thumb/")
      .to_return(status: 200, headers: { "Content-Type" => "image/jpeg" }, body: @image_bytes)
  end

  def with_env(values)
    previous = values.to_h { |key, _value| [ key, ENV[key] ] }
    values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
