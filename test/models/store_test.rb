# frozen_string_literal: true

require "test_helper"

class StoreTest < ActiveSupport::TestCase
  test "business stores require a tax id" do
    store = Store.new(user: users(:admin), name: "Business Bits", kind: :business)

    assert_not store.valid?
    assert store.errors[:tax_id].any?

    store.tax_id = "B12345674"
    assert store.valid?
  end

  test "individual stores do not require a tax id" do
    store = Store.new(user: users(:admin), name: "Solo Bits", kind: :individual)

    assert store.valid?
  end

  test "business postal codes must have five digits in Spain" do
    store = Store.new(user: users(:admin), name: "Postal Bits", kind: :business,
                      tax_id: "B12345674", region: regions(:madrid),
                      city: "Madrid", country_code: "ES", postal_code: "2800")

    assert_not store.valid?(:onboarding)
    assert store.errors[:postal_code].any?
  end

  test "generates a slug from the name" do
    store = Store.create!(user: users(:admin), name: "Admin's PC Corner")

    assert_equal "admin-s-pc-corner", store.slug
  end

  test "a user can only have one store" do
    store = Store.new(user: users(:confirmed), name: "Second Store")

    assert_not store.valid?
    assert store.errors[:user_id].any?
  end

  test "active scope excludes suspended stores" do
    assert_includes Store.active, stores(:confirmed_store)
    assert_not_includes Store.active, stores(:suspended_store)
  end

  test "verified scope only includes stores with a verified timestamp" do
    assert_includes Store.verified, stores(:confirmed_store)
    assert_not_includes Store.verified, stores(:suspended_store)
  end

  test "verified? reflects the timestamp" do
    assert stores(:confirmed_store).verified?
    assert_not stores(:suspended_store).verified?
  end
end
