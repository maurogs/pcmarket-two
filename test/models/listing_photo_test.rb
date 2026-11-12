# frozen_string_literal: true

require "test_helper"

class ListingPhotoTest < ActiveSupport::TestCase
  test "the photo limit comes from Setting.get" do
    Setting.set(:max_images_per_listing, 2)
    listing = create_listing

    2.times { listing.photos.create! }

    third = listing.photos.build
    assert_not third.valid?
    assert third.errors[:base].any?
  end

  test "a different setting allows more photos" do
    Setting.set(:max_images_per_listing, 4)
    listing = create_listing

    4.times { listing.photos.create! }

    assert_equal 4, listing.reload.photos.count
  end

  test "unsupported content types are rejected" do
    photo = create_listing.photos.build
    photo.image.attach(
      io: StringIO.new("definitely not an image"),
      filename: "notes.txt",
      content_type: "text/plain"
    )

    assert_not photo.valid?
    assert photo.errors[:image].any?
  end

  test "unsupported content types report a translated message" do
    photo = create_listing.photos.build
    photo.image.attach(
      io: StringIO.new("definitely not an image"),
      filename: "notes.txt",
      content_type: "text/plain"
    )

    assert_not photo.valid?
    assert_includes photo.errors[:image], I18n.t("errors.messages.invalid_image_type")
  end

  test "images larger than fifteen megabytes are rejected" do
    photo = create_listing.photos.build
    photo.image.attach(
      io: StringIO.new("x" * (15.megabytes + 1)),
      filename: "huge.png",
      content_type: "image/png"
    )

    assert_not photo.valid?
    assert photo.errors[:image].any?
  end

  private

  def create_listing
    Listing.create!(
      store: stores(:confirmed_store),
      seller: users(:confirmed),
      category: categories(:components),
      title: "Photo Test Listing",
      description: "A description long enough to pass the validation checks.",
      price_cents: 10_000,
      specs: {},
      country_code: "ES",
      region: regions(:madrid)
    )
  end
end
