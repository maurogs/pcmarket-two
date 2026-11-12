# frozen_string_literal: true

require "test_helper"

class PcFinderTest < ActionDispatch::IntegrationTest
  setup do
    @gaming = Category.create!(
      name_en: "Gaming PCs", name_es: "PCs gaming", slug: "gaming-pcs",
      position: 20, depth: 0, active: true
    )
    @fortnite = Game.create!(
      name: "Fortnite", slug: "fortnite", position: 1, active: true,
      min_gpu_tier: { "1080p_60" => 3, "1440p_60" => 4, "1440p_144" => 6, "1440p_240" => 9 },
      min_cpu_tier: { "1080p_60" => 2, "1440p_60" => 3, "1440p_144" => 5, "1440p_240" => 8 }
    )
    Game.create!(
      name: "Valorant", slug: "valorant", position: 2, active: true,
      min_gpu_tier: { "1440p_144" => 2 }, min_cpu_tier: { "1440p_144" => 2 }
    )
    @listing = create_listing!(
      store: stores(:confirmed_store), seller: users(:confirmed),
      title: "Fortnite-ready gaming PC", category: @gaming, price_cents: 129_000,
      specs: { "case_colour" => "White", "case_form_factor" => "Mid-Tower",
               "cpu_cooler_type" => "AIO" }
    )
    @listing.update_columns(gpu_tier: 7, cpu_tier: 6)

    @style = Tag.create!(name_en: "Minimalist", name_es: "Minimalista",
                         kind: :seller_tag, position: 1, active: true)
    ListingTag.create!(listing: @listing, tag: @style)

    @cheap = create_listing!(
      store: stores(:confirmed_store), seller: users(:confirmed),
      title: "Budget gaming PC under one thousand", category: @gaming,
      price_cents: 89_000
    )
    @cheap.update_columns(gpu_tier: 4, cpu_tier: 4)
  end

  test "the landing renders the quiz, style tiles and budget rail" do
    get pc_finder_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("pc_finder.quiz.title", locale: :en)
    assert_includes response.body, "Fortnite"
    assert_includes response.body, "Valorant"
    assert_includes response.body, @style.name_en
    assert_includes response.body, I18n.t("pc_finder.landing.budget_title", locale: :en)
    assert_includes response.body, I18n.t("pc_finder.landing.games_title", locale: :en)
    assert_includes response.body, I18n.t("pc_finder.quiz.games_title", locale: :en)
    assert_includes response.body, I18n.t("pc_finder.quiz.vibe_title", locale: :en)
    assert_not_includes response.body, "noindex"
  end

  test "the quiz works as a plain GET form and returns shareable results" do
    get pc_finder_path(locale: :en, games: [ @fortnite.slug ], resolution: "1440p",
                       fps: "144", budget: "1000_1500")

    assert_response :success
    assert_includes response.body, @listing.title
    assert_includes response.body, I18n.t("pc_finder.results.expected", game: "Fortnite", fps: 144,
                                          resolution: "1440p", locale: :en)
    assert_includes response.body, I18n.t("pc_finder.results.add_to_cart", locale: :en)
    assert_includes response.body, "noindex,follow"
    assert_includes response.body, I18n.t("pc_finder.results.chip_fps", fps: 144, locale: :en)
  end

  test "the single-game preset gets a canonical and its own title" do
    get pc_finder_path(locale: :en, game: @fortnite.slug)

    assert_response :success
    assert_includes response.body, "<title>Best gaming PCs for Fortnite | PCMarket</title>"
    assert_includes response.body, pc_finder_url(game: @fortnite.slug, locale: :en)
    assert_not_includes response.body, "noindex"
  end

  test "results with a free-form combination are noindex" do
    get pc_finder_path(locale: :en, games: [ @fortnite.slug, "valorant" ], budget: "under_600")

    assert_response :success
    assert_includes response.body, "noindex,follow"
  end
end
