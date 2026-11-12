ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

# Tests must never hit external services. Localhost stays available so the
# Rails stack and any browser-driven checks keep working.
WebMock.disable_net_connect!(allow_localhost: true)

# Minitest 6 dropped Object#stub, so tests use this small explicit helper to
# replace a method for the duration of a block and restore it afterwards.
module StubbingHelpers
  def with_stub(owner, method_name, replacement)
    original = owner.method(method_name)
    owner.define_singleton_method(method_name) do |*args, **kwargs, &block|
      replacement.respond_to?(:call) ? replacement.call(*args, **kwargs, &block) : replacement
    end
    yield
  ensure
    owner.define_singleton_method(method_name) do |*args, **kwargs, &block|
      original.call(*args, **kwargs, &block)
    end
  end
end

module CacheTestHelpers
  def with_cache(store)
    previous = Rails.cache
    Rails.cache = store
    yield
  ensure
    Rails.cache = previous
  end
end

module ListingSearchTestHelpers
  def insert_bulk_listings(category, count:, prefix: "Bulk", store: stores(:confirmed_store), user: users(:confirmed))
    now = Time.current
    rows = count.times.map do |index|
      {
        store_id: store.id,
        user_id: user.id,
        category_id: category.id,
        title: "#{prefix} listing #{index}",
        description: "A bulk-created listing used by the Phase 2 tests.",
        slug: "#{prefix.parameterize}-#{index}-#{SecureRandom.hex(2)}",
        condition: Listing.conditions[:used_good],
        price_cents: 10_000 + index,
        currency: "EUR",
        quantity: 1,
        specs: {},
        status: "published",
        published_at: now - index.minutes,
        country_code: "ES",
        region_id: regions(:madrid).id,
        shipping_mode: Listing.shipping_modes[:shipping],
        shipping_price_cents: 0,
        free_shipping: false,
        handling_days: 3,
        allow_offers: true,
        views_count: 0,
        favorites_count: 0,
        created_at: now,
        updated_at: now
      }
    end
    Listing.insert_all!(rows)
    rows
  end
end

module ModernBrowserRequests
  MODERN_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/131.0.0.0 Safari/537.36"

  # `allow_browser versions: :modern` rejects the default integration-test
  # User-Agent, so every request gets the modern Chrome header unless a test
  # deliberately overrides it.
  def process(method, path, **kwargs)
    headers = (kwargs[:headers] || {}).merge("User-Agent" => MODERN_USER_AGENT)
    super(method, path, **kwargs.merge(headers: headers))
  end
end

module MarketplaceTestHelpers
  def default_address_attributes
    {
      full_name: "Test Buyer",
      line1: "Calle Mayor 1",
      city: "Madrid",
      region_id: regions(:madrid).id,
      postal_code: "28001",
      country_code: "ES",
      phone: "600000000"
    }
  end

  def checkout_params(fulfilment: {}, **overrides)
    params = {
      email: "buyer@example.com",
      terms_accepted: "1",
      address: default_address_attributes
    }.merge(overrides)
    params[:fulfilment] = fulfilment
    params
  end

  def build_cart(user:, listings:, quantities: {})
    cart = Cart.create!(user: user)
    listings.each do |listing|
      cart.items.create!(listing: listing, quantity: quantities.fetch(listing.id, 1))
    end
    cart
  end

  def create_listing!(store:, seller:, title: "Test listing", price_cents: 10_000, quantity: 1, **attrs)
    Listing.create!(
      {
        store: store,
        seller: seller,
        category: categories(:cpus),
        title: title,
        description: "A test listing used by the Phase 4 marketplace tests.",
        condition: :used_good,
        price_cents: price_cents,
        quantity: quantity,
        status: "published",
        published_at: Time.current,
        country_code: "ES",
        region: regions(:madrid),
        city: "Madrid",
        postal_code: "28001",
        shipping_mode: "shipping",
        shipping_price_cents: 0,
        handling_days: 2
      }.merge(attrs)
    )
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include CacheTestHelpers
    include ListingSearchTestHelpers
    include MarketplaceTestHelpers
    include StubbingHelpers

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  prepend ModernBrowserRequests
end
