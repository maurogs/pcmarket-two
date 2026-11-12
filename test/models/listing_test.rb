# frozen_string_literal: true

require "test_helper"

class ListingTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------- validations

  test "a draft listing does not need the required category specs" do
    assert build_listing(category: categories(:gpus), specs: {}).valid?
  end

  test "required category specs are enforced when the listing leaves draft" do
    listing = build_listing(category: categories(:gpus), specs: {},
                            status: "pending_review")

    assert_not listing.valid?
    assert listing.errors[:specs].any?
  end

  test "submitting without the required specs fails while draft specs stay valid" do
    listing = build_listing(category: categories(:gpus), specs: {})

    assert_raises(ActiveRecord::RecordInvalid) { listing.submit! }

    listing.specs = { "gpu_chipset" => "nvidia" }
    assert listing.submit!
    assert_equal "pending_review", listing.status
  end

  test "spec values must be active options of a select definition" do
    inactive = build_listing(category: categories(:gpus),
                             specs: { "gpu_chipset" => "legacy" })
    unknown = build_listing(category: categories(:gpus),
                            specs: { "gpu_chipset" => "made-up" })

    assert_not inactive.valid?
    assert inactive.errors[:specs].any?
    assert_not unknown.valid?
    assert unknown.errors[:specs].any?
  end

  test "title and description lengths are enforced" do
    assert_not build_listing(title: "abc").valid?
    assert_not build_listing(description: "too short").valid?
  end

  test "price must be greater than zero" do
    assert_not build_listing(price_cents: 0).valid?
  end

  test "price must be within the configured euro range" do
    Setting.set(:min_listing_price, 100)
    Setting.set(:max_listing_price, 200)

    assert_not build_listing(price_cents: 5_000).valid?   # 50 EUR
    assert build_listing(price_cents: 15_000).valid?      # 150 EUR
    assert_not build_listing(price_cents: 25_000).valid?  # 250 EUR
  end

  test "compare_at_price_cents must be greater than the price" do
    assert_not build_listing(price_cents: 10_000,
                             compare_at_price_cents: 10_000).valid?
    assert build_listing(price_cents: 10_000,
                         compare_at_price_cents: 12_000).valid?
  end

  test "quantity and handling_days are bounded" do
    assert_not build_listing(quantity: -1).valid?
    assert_not build_listing(handling_days: 0).valid?
    assert_not build_listing(handling_days: 11).valid?
  end

  test "country_code must be a launched country" do
    assert_not build_listing(country_code: "FR", region: regions(:ile_de_france)).valid?
    assert build_listing(country_code: "ES", region: regions(:madrid)).valid?
  end

  test "the region must belong to the listing country" do
    assert_not build_listing(country_code: "ES", region: regions(:ile_de_france)).valid?
  end

  # ------------------------------------------------------------------ state machine

  test "submit goes to pending_review when approval is required" do
    listing = build_listing
    listing.save!

    assert listing.submit!
    assert_equal "pending_review", listing.status
    assert listing.submitted_at.present?
    assert_nil listing.published_at
  end

  test "submit publishes directly when approval is disabled" do
    Setting.set(:listings_require_approval, false)
    listing = build_listing
    listing.save!

    assert listing.submit!
    assert_equal "published", listing.status
    assert listing.published_at.present?
    assert listing.submitted_at.present?
  end

  test "submit from rejected clears the rejection reason" do
    listing = build_listing(status: "rejected", rejection_reason: "bad photos")
    listing.save!

    assert listing.submit!
    assert_equal "pending_review", listing.status
    assert_nil listing.rejection_reason
  end

  test "approve publishes and clears the rejection reason" do
    listing = build_listing(status: "pending_review", rejection_reason: "old")
    listing.save!

    assert listing.approve!
    assert_equal "published", listing.status
    assert listing.published_at.present?
    assert_nil listing.rejection_reason
  end

  test "reject stores the reason" do
    listing = build_listing(status: "pending_review")
    listing.save!

    assert listing.reject!("blurry photos")
    assert_equal "rejected", listing.status
    assert_equal "blurry photos", listing.rejection_reason
  end

  test "reject requires a reason" do
    listing = build_listing(status: "pending_review")
    listing.save!

    assert_not listing.reject
    assert_equal "pending_review", listing.status
  end

  test "reserve and release round-trip through checkout" do
    listing = build_listing(status: "published", published_at: Time.current)
    listing.save!

    assert listing.reserve!
    assert_equal "reserved", listing.status
    assert listing.release!
    assert_equal "published", listing.status
  end

  test "mark_sold works from published and from reserved" do
    published = build_listing(status: "published", published_at: Time.current)
    published.save!
    assert published.mark_sold!
    assert_equal "sold", published.status
    assert published.sold_at.present?

    reserved = build_listing(status: "reserved")
    reserved.save!
    assert reserved.mark_sold!
    assert_equal "sold", reserved.status
  end

  test "archive sets archived_at and excludes sold listings" do
    listing = build_listing(status: "published", published_at: Time.current)
    listing.save!

    assert listing.archive!
    assert_equal "archived", listing.status
    assert listing.archived_at.present?

    sold = build_listing(status: "sold")
    sold.save!
    assert_not sold.archive
    assert_equal "sold", sold.status
  end

  test "republish follows the approval rule" do
    listing = build_listing(status: "archived", archived_at: Time.current)
    listing.save!
    assert listing.republish!
    assert_equal "pending_review", listing.status
    assert_nil listing.archived_at

    Setting.set(:listings_require_approval, false)
    other = build_listing(status: "archived", archived_at: Time.current)
    other.save!
    assert other.republish!
    assert_equal "published", other.status
    assert other.published_at.present?
  end

  test "material edits of a published listing return it to review" do
    listing = build_listing(status: "published", published_at: Time.current)
    listing.save!

    listing.update!(title: "A Completely Updated Graphics Card")
    assert_equal "pending_review", listing.status
  end

  test "price and shipping edits of a published listing stay live" do
    listing = build_listing(status: "published", published_at: Time.current)
    listing.save!

    listing.update!(price_cents: 26_000, shipping_price_cents: 500, quantity: 2)
    assert_equal "published", listing.status
  end

  test "material edits stay live when approval is disabled" do
    Setting.set(:listings_require_approval, false)
    listing = build_listing(status: "published", published_at: Time.current)
    listing.save!

    listing.update!(title: "Another Updated Graphics Card")
    assert_equal "published", listing.status
  end

  test "adding a photo is a material edit" do
    listing = build_listing(status: "published", published_at: Time.current)
    listing.save!

    listing.photos.create!
    assert_equal "pending_review", listing.reload.status
  end

  # ------------------------------------------------------------------ counters

  test "published listings increment and decrement store and category counters" do
    store = stores(:confirmed_store)
    category = categories(:components)
    before_store = store.listings_count
    before_category = category.listings_count

    listing = build_listing(category: category)
    listing.save!
    listing.submit!
    listing.approve!

    assert_equal before_store + 1, store.reload.listings_count
    assert_equal before_category + 1, category.reload.listings_count

    listing.archive!

    assert_equal before_store, store.reload.listings_count
    assert_equal before_category, category.reload.listings_count
  end

  test "counter updates are skipped when the published tuple is unchanged" do
    listing = build_listing(status: "published", published_at: Time.current)
    listing.save!
    count = stores(:confirmed_store).reload.listings_count

    listing.update!(price_cents: 27_000)

    assert_equal count, stores(:confirmed_store).reload.listings_count
  end

  # --------------------------------------------------------------------- scopes

  test "visible excludes drafts, suspended stores and banned sellers" do
    assert_includes Listing.visible, listings(:published_gpu)
    assert_not_includes Listing.visible, listings(:draft_gpu)
    assert_not_includes Listing.visible, listings(:pending_gpu)
    assert_not_includes Listing.visible, listings(:suspended_listing)
    assert_not_includes Listing.visible, listings(:banned_listing)
  end

  test "in_category uses the descendant tree" do
    results = Listing.in_category(categories(:components))

    assert_includes results, listings(:published_gpu)
    assert_includes results, listings(:accent_gpu)
    assert_includes results, listings(:cpu_listing)
  end

  test "in_category on a leaf only returns that category" do
    assert_equal [ listings(:cpu_listing) ],
                 Listing.in_category(categories(:cpus)).to_a
  end

  test "by_condition, price_between, in_region and featured scopes" do
    assert_includes Listing.by_condition(:used_like_new), listings(:published_gpu)
    assert_includes Listing.price_between(20_000..80_000), listings(:amd_gpu)
    assert_not_includes Listing.price_between(20_000..80_000), listings(:accent_gpu)
    assert_includes Listing.in_region(regions(:madrid)), listings(:published_gpu)
    assert_includes Listing.featured, listings(:published_gpu)
    assert_not_includes Listing.featured, listings(:amd_gpu)
  end

  test "with_specs matches a single scalar value" do
    results = Listing.with_specs("gpu_chipset" => "nvidia")

    assert_includes results, listings(:published_gpu)
    assert_includes results, listings(:nvidia_budget)
    assert_not_includes results, listings(:amd_gpu)
  end

  test "with_specs ORs multiple values of the same key" do
    results = Listing.with_specs("gpu_memory_type" => %w[gddr6 gddr6x])

    assert_includes results, listings(:published_gpu)
    assert_includes results, listings(:amd_gpu)
    assert_includes results, listings(:nvidia_budget)
  end

  test "with_specs ANDs across keys" do
    results = Listing.with_specs("gpu_chipset" => "nvidia",
                                 "gpu_memory_type" => "gddr6x")

    assert_includes results, listings(:published_gpu)
    assert_not_includes results, listings(:nvidia_budget)
    assert_not_includes results, listings(:amd_gpu)
  end

  test "with_specs with an empty filter returns everything" do
    assert_equal Listing.count, Listing.with_specs({}).count
  end

  test "with_specs matches array-valued specs through containment" do
    results = Listing.with_specs("gpu_memory_type" => "gddr6x")

    assert_includes results, listings(:published_gpu)
    assert_not_includes results, listings(:amd_gpu)
  end

  test "sorted_by supports newest, price and popularity" do
    assert_equal Listing.published.order(price_cents: :asc, id: :asc).pluck(:id),
                 Listing.published.sorted_by(:price_asc).pluck(:id)
    assert_equal Listing.published.order(price_cents: :desc, id: :desc).pluck(:id),
                 Listing.published.sorted_by(:price_desc).pluck(:id)
    assert_equal Listing.published.order(published_at: :desc, id: :desc).pluck(:id),
                 Listing.published.sorted_by(:newest).pluck(:id)
    assert listings(:published_gpu).favorites_count.positive?
    assert_equal Listing.published.order(favorites_count: :desc, views_count: :desc, id: :desc).pluck(:id),
                 Listing.published.sorted_by(:popular).pluck(:id)
  end

  # -------------------------------------------------------------------- search

  test "search_text is accent insensitive" do
    assert_includes Listing.search_text("grafica"), listings(:accent_gpu)
    assert_includes Listing.search_text("gráfica"), listings(:accent_gpu)
  end

  test "search_text matches prefixes" do
    assert_includes Listing.search_text("grafic"), listings(:accent_gpu)
    assert_includes Listing.search_text("gefor"), listings(:published_gpu)
    assert_not_includes Listing.search_text("zzzznotaterm"), listings(:published_gpu)
  end

  test "search_text relevance sorting works" do
    assert_includes Listing.search_text("gefor").sorted_by(:relevance),
                   listings(:published_gpu)
  end

  # --------------------------------------------------------------------- helpers

  test "price converts cents to a decimal" do
    assert_equal BigDecimal("799"), listings(:published_gpu).price
  end

  test "slug is the title slugified plus a six character hex suffix" do
    listing = build_listing
    listing.save!

    assert_match(/\Atest-graphics-card-[0-9a-f]{6}\z/, listing.slug)
  end

  test "description, specs and category edits are material" do
    edits = [
      { description: "An updated description that is long enough to validate." },
      { specs: { "gpu_chipset" => "nvidia" } },
      { category: categories(:cpus) }
    ]

    edits.each do |edit|
      listing = build_listing(status: "published", published_at: Time.current)
      listing.save!
      listing.update!(edit)

      assert_equal "pending_review", listing.status,
                   "expected #{edit.keys.first} to require a new review"
    end
  end

  test "removing a photo is a material edit" do
    listing = build_listing
    listing.save!
    photo = listing.photos.create!
    listing.update!(status: "published", published_at: Time.current)

    photo.destroy!

    assert_equal "pending_review", listing.reload.status
  end

  test "destroying a published listing with photos decrements the counters" do
    listing = build_listing
    listing.save!
    listing.photos.create!
    listing.update!(status: "published", published_at: Time.current)

    store = listing.store
    category = listing.category
    before_store = store.reload.listings_count
    before_category = category.reload.listings_count

    assert_nothing_raised { listing.destroy! }

    assert_equal before_store - 1, store.reload.listings_count
    assert_equal before_category - 1, category.reload.listings_count
  end

  test "discount_percent is derived from the compare-at price" do
    assert_equal 11, listings(:published_gpu).discount_percent
    assert_nil build_listing(compare_at_price_cents: nil).discount_percent
  end

  test "primary_photo is the first ordered photo" do
    listing = build_listing
    listing.save!
    first = listing.photos.create!(position: 2)
    listing.photos.create!(position: 1)

    assert_equal listing.photos.order(:position).first.id, listing.reload.primary_photo.id
    assert_not_equal first.id, listing.primary_photo.id
  end

  private

  def build_listing(attributes = {})
    Listing.new({
      store: stores(:confirmed_store),
      seller: users(:confirmed),
      category: categories(:components),
      title: "Test Graphics Card",
      description: "A description that is definitely long enough to validate.",
      price_cents: 25_000,
      specs: {},
      country_code: "ES",
      region: regions(:madrid),
      shipping_mode: :shipping,
      handling_days: 3
    }.merge(attributes))
  end
end
