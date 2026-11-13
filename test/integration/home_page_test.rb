# frozen_string_literal: true

require "test_helper"

class HomePageTest < ActionDispatch::IntegrationTest
  setup do
    @gaming = Category.create!(
      name_en: "Gaming PCs", name_es: "PCs gaming", slug: "gaming-pcs",
      position: 20, depth: 0, active: true
    )
    @gaming_listing = create_listing!(
      store: stores(:confirmed_store),
      seller: users(:confirmed),
      title: "Gaming PC ready to ship",
      category: @gaming,
      handling_days: 2,
      price_cents: 120_000,
      compare_at_price_cents: 150_000
    )

    @style_tag = Tag.create!(name_en: "Minimalist", name_es: "Minimalista", kind: :seller_tag,
                             position: 1, active: true)
    ListingTag.create!(listing: @gaming_listing, tag: @style_tag)

    Favourite.create!(user: users(:moderator), listing: listings(:published_gpu))
    ListingView.increment_for(listings(:published_gpu).id)

    @sold = create_listing!(
      store: stores(:confirmed_store),
      seller: users(:confirmed),
      title: "Recently sold GPU",
      category: categories(:components),
      status: "sold",
      sold_at: Time.current
    )

    Review.create!(
      order: create_order!(status: "delivered", delivered_at: Time.current,
                           store: stores(:confirmed_store)),
      reviewer: users(:confirmed),
      store: stores(:confirmed_store),
      rating: 5,
      body: "A genuinely excellent experience from start to finish. The packaging was careful and the item was exactly as described."
    )
  end

  test "renders every populated section with SEO structured data" do
    get "/"

    assert_response :success
    assert_includes response.body, I18n.t("home.deals.title")
    assert_includes response.body, I18n.t("home.promos.title")
    assert_includes response.body, I18n.t("home.pc_finder.title")
    assert_includes response.body, @style_tag.name
    assert_includes response.body, I18n.t("home.rails.new_gpus")
    assert_includes response.body, I18n.t("home.rails.most_watched")
    assert_includes response.body, I18n.t("home.rails.on_sale")
    assert_includes response.body, I18n.t("home.sell.title")
    assert_includes response.body, I18n.t("home.sold.title")
    assert_includes response.body, I18n.t("home.sold.badge")
    assert_includes response.body, "A genuinely excellent experience"
    assert_includes response.body, I18n.t("home.trust.protection.title")

    assert_includes response.body, '"@type":"Organization"'
    assert_includes response.body, '"@type":"WebSite"'
    assert_includes response.body, '"@type":"SearchAction"'
  end

  test "hides data sections when the catalogue is empty" do
    Favourite.delete_all
    ListingView.delete_all
    Review.delete_all
    Listing.find_each(&:destroy)

    get "/"

    assert_response :success
    assert_not_includes response.body, I18n.t("home.deals.title")
    assert_not_includes response.body, I18n.t("home.rails.new_gpus")
    assert_not_includes response.body, I18n.t("home.sold.title")
    assert_includes response.body, I18n.t("home.pc_finder.title")
    assert_includes response.body, I18n.t("home.sell.title")
  end

  test "serves the cached sections without repeating listing queries" do
    store = ActiveSupport::Cache::MemoryStore.new

    with_cache(store) do
      get "/"
      assert_response :success

      queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        next if payload[:cached]
        next if payload[:name] == "SCHEMA"
        next if payload[:sql].match?(/\A(BEGIN|COMMIT|SAVEPOINT|RELEASE SAVEPOINT)/)

        queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get "/"
      end

      assert_response :success
      assert_operator queries.size, :<, 15,
                      "Expected cached sections to avoid listing queries, got #{queries.size}:\n#{queries.join("\n")}"
    end
  end

  test "home page copy is translated" do
    get "/en"

    assert_response :success
    assert_includes response.body, I18n.t("home.deals.title", locale: :en)
    assert_includes response.body, I18n.t("home.seo.title", locale: :en)
  end
end
