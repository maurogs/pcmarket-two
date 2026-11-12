# frozen_string_literal: true

require "test_helper"

class StorefrontsTest < ActionDispatch::IntegrationTest
  setup do
    @store = stores(:confirmed_store)
    @buyer = users(:moderator)
  end

  def delivered_order(store: @store, buyer: @buyer)
    checkout = Checkout.create!(
      buyer: buyer,
      email: buyer.email,
      shipping_address: default_address_attributes.stringify_keys
    )
    Order.create!(
      checkout: checkout,
      buyer: buyer,
      store: store,
      status: "delivered",
      delivered_at: Time.current,
      paid_at: Time.current,
      subtotal_cents: 10_000,
      shipping_cents: 0,
      commission_cents: 0,
      total_cents: 10_000,
      currency: "EUR"
    )
  end

  def create_business_store
    owner = User.create!(
      username: "legal_seller",
      email: "legal@example.com",
      password: "Password123!",
      first_name: "Legal",
      last_name: "Seller",
      country_code: "ES",
      locale: "es",
      confirmed_at: Time.current,
      terms_accepted: "1"
    )
    Store.create!(
      user: owner,
      name: "Legal Components SL",
      kind: :business,
      country_code: "ES",
      region: regions(:madrid),
      city: "Madrid",
      postal_code: "28001",
      legal_name: "Legal Components Sociedad Limitada",
      tax_id: "B12345674",
      address_line: "Calle Legal 10"
    )
  end

  test "renders the listings tab with header, filters and recently sold items" do
    get storefront_path(@store, locale: :en)

    assert_response :success
    assert_includes response.body, @store.name
    assert_includes response.body, I18n.t("storefronts.header.for_sale", locale: :en)
    assert_includes response.body, listings(:published_gpu).title
    assert_includes response.body, I18n.t("storefronts.sold.title", locale: :en)
    assert_includes response.body, listings(:sold_gpu).title
    assert_includes response.body, I18n.t("storefronts.sold.badge", locale: :en)
    assert_includes response.body, 'name="q"'
    assert_includes response.body, 'name="condition"'
  end

  test "renders the about tab with policies and the business legal block" do
    business = create_business_store

    get storefront_path(business, tab: "about", locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("storefronts.about.legal_title", locale: :en)
    assert_includes response.body, "Legal Components Sociedad Limitada"
    assert_includes response.body, "B12345674"
    assert_includes response.body, "Calle Legal 10"
    assert_includes response.body, I18n.t("storefronts.about.policies_title", locale: :en)
  end

  test "renders reviews with distribution, seller replies and JSON-LD aggregate rating" do
    order = delivered_order
    review = Review.create!(
      order: order,
      reviewer: @buyer,
      store: @store,
      rating: 5,
      body: "Exactly as described and packed with care."
    )
    review.update!(seller_reply: "Thank you for your kind words.", seller_replied_at: Time.current)

    get storefront_path(@store, tab: "reviews", locale: :en)

    assert_response :success
    assert_includes response.body, "Exactly as described and packed with care."
    assert_includes response.body, "Thank you for your kind words."
    assert_includes response.body, I18n.t("storefronts.reviews.seller_reply", locale: :en)
    assert_includes response.body, '"aggregateRating"'
    assert_includes response.body, '"ratingValue":"5.00"'
  end

  test "business JSON-LD uses Organization" do
    business = create_business_store
    order = delivered_order(store: business)
    Review.create!(order: order, reviewer: @buyer, store: business, rating: 4,
                   body: "Reliable business seller with clear communication.")

    get storefront_path(business, locale: :en)

    assert_response :success
    assert_includes response.body, '"@type":"Organization"'
    assert_includes response.body, '"vatID":"B12345674"'
  end

  test "individual JSON-LD uses Person without an aggregate rating when there are no reviews" do
    get storefront_path(@store, locale: :en)

    assert_response :success
    assert_includes response.body, '"@type":"Person"'
    assert_not_includes response.body, '"aggregateRating"'
  end

  test "a suspended store returns 404" do
    get storefront_path(stores(:suspended_store), locale: :en)

    assert_response :not_found
  end
end
