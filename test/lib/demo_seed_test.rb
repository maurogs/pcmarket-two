# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "open3"
require "json"

class DemoSeedTest < ActiveSupport::TestCase
  test "seeds a valid small marketplace and reset removes only demo rows" do
    load_catalogue_seeds
    image_root = Dir.mktmpdir("demo-seed-images")
    build_image_library(image_root)

    library = Demo::ImageLibrary.new(root: image_root, providers: [], logger: Logger.new(nil),
                                     sleeper: ->(_seconds) { })
    seed = Demo::Seed.new(scale: 0.02, logger: Logger.new(nil), image_library: library, rng: Random.new(2026))
    summary = seed.call

    assert_equal 5, summary[:counts][:users]
    assert_equal 1, summary[:counts][:stores]
    assert_equal 30, summary[:counts][:listings]
    assert_equal User.where(demo: true).count, summary[:counts][:users]
    assert_equal Store.where(demo: true).count, summary[:counts][:stores]
    assert_equal Listing.where(demo: true).count, summary[:counts][:listings]

    assert_equal 1, Store.where(demo: true, kind: :business).count
    assert_equal 0, Store.where(demo: true, kind: :individual).count
    assert Store.where(demo: true, kind: :business).all? { |store| store.tax_id.present? }
    Store.where(demo: true).find_each do |store|
      assert store.valid?, "demo store #{store.id} is invalid: #{store.errors.full_messages.to_sentence}"
      assert_predicate store, :payouts_ready?
    end
    assert Store.where(demo: true).all?(&:payouts_enabled?)
    assert Store.where(demo: true).all? { |store| store.region_id.present? }

    published = Listing.where(demo: true, status: "published").includes(:category, :photos)
    assert_operator published.count, :>, 0
    ratio = published.count.to_f / Listing.where(demo: true).count
    assert_operator ratio, :>=, 0.6
    assert_operator ratio, :<=, 0.95

    published.find_each do |listing|
      assert listing.valid?(:review), "published listing #{listing.id} is invalid: #{listing.errors.full_messages.to_sentence}"
      assert_operator listing.price_cents, :>=, Setting.get(:min_listing_price, 1).to_i * 100
      assert_operator listing.price_cents, :<=, Setting.get(:max_listing_price, 50_000).to_i * 100
      assert_includes 2..6, listing.photos.size
      assert_equal "ES", listing.country_code
      assert listing.region.present?
      assert listing.city.present?
      assert_match(/\A\d{5}\z/, listing.postal_code)

      listing.category.effective_category_attributes.select(&:required?).each do |category_attribute|
        definition = category_attribute.attribute_definition
        value = listing.specs[definition.key]
        present = value.is_a?(Array) ? value.any?(&:present?) : value.present?
        assert present, "#{listing.category.slug} listing #{listing.id} is missing required spec #{definition.key}"
      end

      next unless listing.compare_at_price_cents

      assert_operator listing.compare_at_price_cents, :>, listing.price_cents
    end

    Listing.where(demo: true).find_each do |listing|
      assert_operator listing.gpu_tier, :>=, 0
      assert_operator listing.cpu_tier, :>=, 0
    end

    Store.where(demo: true).find_each do |store|
      assert_equal store.listings.where(status: "published").count, store.listings_count
      assert_equal store.reviews.visible_reviews.count, store.ratings_count
      assert_equal store.follows.count, store.followers_count
      assert_equal store.orders.where(status: "completed").count, store.sales_count
    end

    Category.find_each do |category|
      assert_equal Listing.where(category_id: category.id, status: "published").count,
                   category.listings_count
    end

    Listing.where(demo: true).find_each do |listing|
      assert_equal listing.favourites.count, listing.favorites_count
      assert_equal ListingView.where(listing_id: listing.id).sum(:views), listing.views_count
    end

    assert_operator Favourite.count, :>, 0
    assert_operator Follow.count, :>, 0
    assert_operator Conversation.count, :>, 0
    assert_operator Message.count, :>, 0
    assert_operator Order.where(status: "completed").count, :>, 0
    assert_operator Review.count, :>, 0
    assert_operator ListingView.count, :>, 0
    assert_operator Notification.count, :>, 0
    assert_operator Report.where(status: :open).count, :>, 0

    assert_equal 0, Review.where.not(store_id: Store.where(demo: true).select(:id)).count
    assert Order.where(status: "completed").all? { |order| order.delivered_at.present? }

    non_demo_user_id = users(:confirmed).id
    non_demo_listing_id = listings(:published_gpu).id

    Demo::Reset.new(logger: Logger.new(nil)).call
    assert_equal 0, User.where(demo: true).count
    assert_equal 0, Store.where(demo: true).count
    assert_equal 0, Listing.where(demo: true).count
    assert_equal 0, ListingView.joins(:listing).where(listings: { demo: true }).count
    assert_equal 0, Conversation.where(buyer_id: User.where(demo: true).select(:id)).count
    assert User.exists?(non_demo_user_id), "reset must keep real users"
    assert Listing.exists?(non_demo_listing_id), "reset must keep real listings"
  ensure
    FileUtils.rm_rf(image_root) if image_root
  end

  private

  def load_catalogue_seeds
    load Rails.root.join("db/seeds/categories.rb")
    load Rails.root.join("db/seeds/attributes.rb")
    load Rails.root.join("db/seeds/tags.rb")
  end

  # One cached photo per category keeps the seed test fast while exercising the
  # same blob/manifest path as a downloaded library.
  def build_image_library(root)
    source = File.join(root, "source.jpg")
    _out, _err, status = Open3.capture3("magick", "-size", "800x600", "gradient:#1e293b-#4338ca", source)
    skip "ImageMagick is required for the demo seed test" unless status.success?

    library = Demo::ImageLibrary.new(root: root, providers: [], logger: Logger.new(nil),
                                     sleeper: ->(_seconds) { })
    library.categories.each do |slug|
      directory = File.join(root, slug)
      FileUtils.mkdir_p(directory)
      filename = "openverse-#{slug}.jpg"
      FileUtils.cp(source, File.join(directory, filename))
      File.write(File.join(directory, "manifest.json"), JSON.pretty_generate([ {
        "file" => filename,
        "provider" => "openverse",
        "external_id" => slug,
        "title" => "#{slug} demo photo",
        "source_url" => "https://example.com/photos/#{slug}",
        "author" => "Demo Author",
        "author_url" => "https://example.com/author",
        "license" => "CC BY 4.0",
        "license_url" => "https://creativecommons.org/licenses/by/4.0/",
        "downloaded_at" => Time.current.iso8601
      } ]))
    end
  end
end
