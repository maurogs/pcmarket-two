# frozen_string_literal: true

require "test_helper"

class ListingWizardValidationTest < ActiveSupport::TestCase
  test "the category step only validates the category" do
    listing = build_listing(title: nil, description: nil, price_cents: nil,
                            region: nil, city: nil, postal_code: nil)

    assert listing.valid?(:category)
  end

  test "the photos step requires at least one photo" do
    listing = build_listing

    assert_not listing.valid?(:photos)
    assert listing.errors[:photos].any?

    attach_photo(listing)
    assert listing.valid?(:photos)
  end

  test "the details step does not require price or location fields yet" do
    listing = build_listing(price_cents: nil, region: nil, city: nil, postal_code: nil,
                            specs: { "gpu_chipset" => "nvidia" })

    assert listing.valid?(:details)
  end

  test "the details step enforces required category attributes" do
    listing = build_listing(specs: {})

    assert_not listing.valid?(:details)
    assert listing.errors[:specs].any?
  end

  test "the price step requires a price and location but not photos" do
    listing = build_listing(price_cents: nil, region: nil, city: nil, postal_code: nil,
                            specs: { "gpu_chipset" => "nvidia" })

    assert_not listing.valid?(:price)
    assert listing.errors[:price_cents].any?
    assert listing.errors[:region].any?

    listing.price_cents = 25_000
    listing.region = regions(:madrid)
    listing.city = "Madrid"
    listing.postal_code = "28001"
    assert listing.valid?(:price)
  end

  test "the compare-at price must be higher during the price step" do
    listing = build_listing(price_cents: 10_000, compare_at_price_cents: 9_000,
                            specs: { "gpu_chipset" => "nvidia" })

    assert_not listing.valid?(:price)
    assert listing.errors[:compare_at_price_cents].any?
  end

  test "the review step requires every field" do
    listing = build_listing(specs: { "gpu_chipset" => "nvidia" })

    assert_not listing.valid?(:review)
    assert listing.errors[:photos].any?

    attach_photo(listing)
    assert listing.valid?(:review)
  end

  test "individual stores are fixed to one unit during the price step" do
    listing = build_listing(quantity: 2, specs: { "gpu_chipset" => "nvidia" })

    assert_not listing.valid?(:price)
    assert listing.errors[:quantity].any?
  end

  private

  def build_listing(attributes = {})
    Listing.new({
      store: stores(:confirmed_store),
      seller: users(:confirmed),
      category: categories(:gpus),
      title: "Test Graphics Card",
      description: "A description that is definitely long enough to validate.",
      price_cents: 25_000,
      specs: {},
      country_code: "ES",
      region: regions(:madrid),
      city: "Madrid",
      postal_code: "28001",
      shipping_mode: :shipping,
      handling_days: 3
    }.merge(attributes))
  end

  def attach_photo(listing)
    listing.photos.build.image.attach(
      io: File.open(file_fixture("listing.png")),
      filename: "listing.png",
      content_type: "image/png"
    )
  end
end
