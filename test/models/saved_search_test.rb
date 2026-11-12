# frozen_string_literal: true

require "test_helper"

class SavedSearchTest < ActiveSupport::TestCase
  setup do
    @user = users(:moderator)
  end

  def build_search(query_params: {}, category: nil, **attrs)
    SavedSearch.new({
      user: @user,
      name: "Search",
      query_params: query_params,
      category: category,
      frequency: "daily",
      email_alerts: true
    }.merge(attrs))
  end

  test "normalizes string keys and drops unknown params" do
    search = build_search(query_params: {
      "q" => "  RTX  ",
      "min_price" => "100",
      "bogus" => "value",
      "page" => "3"
    })
    search.save!

    assert_equal({ "q" => "RTX", "min_price" => 100.0 }, search.reload.query_params)
  end

  test "swaps an inverted price range" do
    search = build_search(query_params: { "min_price" => "500", "max_price" => "100" })
    search.save!

    assert_equal 100.0, search.reload.query_params["min_price"]
    assert_equal 500.0, search.reload.query_params["max_price"]
  end

  test "keeps a non-default sort and always drops the page" do
    search = build_search(query_params: { "sort" => "price_asc", "page" => "4" })
    search.save!

    assert_equal({ "sort" => "price_asc" }, search.reload.query_params)

    default_sort = build_search(name: "Default sort", query_params: { "sort" => "best_match" })
    default_sort.save!

    assert_equal({}, default_sort.reload.query_params)
  end

  test "drops invalid values and non-hash spec payloads" do
    search = build_search(query_params: {
      "min_price" => "abc",
      "max_price" => "-10",
      "condition" => [ "bogus" ],
      "region" => "xx",
      "tags" => "featured",
      "specs" => "nope"
    })
    search.save!

    assert_equal({}, search.reload.query_params)
  end

  test "only keeps spec keys allowed by the category" do
    gpus = categories(:gpus)
    search = build_search(
      category: gpus,
      query_params: { "specs" => { "gpu_chipset" => [ "nvidia" ], "warranty" => [ "12" ] } }
    )
    search.save!

    assert_equal({ "specs" => { "gpu_chipset" => [ "nvidia" ] } }, search.reload.query_params)
  end

  test "drops every spec key when there is no category" do
    search = build_search(query_params: { "specs" => { "gpu_chipset" => [ "nvidia" ] } })
    search.save!

    assert_equal({}, search.reload.query_params)
  end

  test "caps a user at 50 saved searches" do
    SavedSearch::MAX_PER_USER.times do |index|
      SavedSearch.create!(user: @user, name: "Search #{index}", query_params: {})
    end

    extra = SavedSearch.new(user: @user, name: "One too many", query_params: {})

    I18n.with_locale(:en) do
      assert_not extra.valid?
      assert_includes extra.errors[:base],
                      I18n.t("saved_searches.errors.limit_reached", max: SavedSearch::MAX_PER_USER)
    end
  end

  test "to_search_params includes the category slug" do
    search = build_search(category: categories(:gpus), query_params: { "q" => "RTX" })

    assert_equal({ "q" => "RTX", "category" => "graphics-cards" }, search.to_search_params)
  end

  test "matches the category subtree, price and condition" do
    search = build_search(
      category: categories(:gpus),
      query_params: { "max_price" => "100", "condition" => [ "used_good" ] }
    )

    match = create_listing!(store: stores(:confirmed_store), seller: users(:confirmed),
                            category: categories(:nvidia), title: "Child GPU",
                            price_cents: 9_000, condition: :used_good,
                            specs: { gpu_chipset: "nvidia" })
    too_expensive = create_listing!(store: stores(:confirmed_store), seller: users(:confirmed),
                                    category: categories(:gpus), title: "Expensive GPU",
                                    price_cents: 50_000, condition: :used_good,
                                    specs: { gpu_chipset: "nvidia" })
    wrong_condition = create_listing!(store: stores(:confirmed_store), seller: users(:confirmed),
                                      category: categories(:gpus), title: "New GPU",
                                      price_cents: 9_000, condition: :new_sealed,
                                      specs: { gpu_chipset: "nvidia" })

    assert search.matches?(match)
    assert_not search.matches?(too_expensive)
    assert_not search.matches?(wrong_condition)
  end

  test "frequency and digest helpers" do
    instant = build_search(frequency: "instant")
    daily = build_search(frequency: "daily")
    weekly = build_search(frequency: "weekly")

    assert instant.instant?
    assert_not instant.digest?
    assert_not instant.digest_due?
    assert instant.email_due?

    assert daily.digest?
    assert daily.digest_due?
    assert daily.email_due?

    daily.last_notified_at = 2.days.ago
    assert daily.digest_due?

    weekly.last_notified_at = 2.days.ago
    assert_not weekly.digest_due?
    assert_not weekly.email_due?

    weekly.last_notified_at = 8.days.ago
    assert weekly.digest_due?
  end

  test "rejects an invalid frequency" do
    search = build_search(frequency: "hourly")

    assert_not search.valid?
    assert search.errors[:frequency].any?
  end
end
