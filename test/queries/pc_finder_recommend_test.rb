# frozen_string_literal: true

require "test_helper"

class PcFinderRecommendTest < ActiveSupport::TestCase
  setup do
    @gaming = Category.create!(
      name_en: "Gaming PCs", name_es: "PCs gaming", slug: "gaming-pcs",
      position: 20, depth: 0, active: true
    )
    @game = Game.create!(
      name: "Fortnite", slug: "fortnite", position: 1, active: true,
      min_gpu_tier: { "1440p_60" => 4, "1440p_144" => 6, "1440p_240" => 9 },
      min_cpu_tier: { "1440p_60" => 3, "1440p_144" => 5, "1440p_240" => 8 }
    )
    @vibe = Tag.create!(name_en: "Minimalist", name_es: "Minimalista",
                        kind: :seller_tag, position: 1, active: true)
  end

  test "requires the hardest game requirement at the chosen resolution and fps" do
    eligible = listing!("Eligible", price: 110_000, gpu: 6, cpu: 5)
    low_gpu = listing!("Low GPU", price: 90_000, gpu: 5, cpu: 8)
    low_cpu = listing!("Low CPU", price: 90_000, gpu: 9, cpu: 4)

    result = recommend(budget: "1000_1500")

    assert_equal [ eligible.id ], result.listings.map(&:id)
    assert_not_includes result.listings.map(&:id), low_gpu.id
    assert_not_includes result.listings.map(&:id), low_cpu.id
  end

  test "uses the maximum requirement across the selected games" do
    hard = Game.create!(name: "Cyberpunk 2077", slug: "cyberpunk-2077", position: 2,
                        min_gpu_tier: { "1440p_144" => 8 },
                        min_cpu_tier: { "1440p_144" => 7 })
    listing!("Mid range gaming PC", price: 110_000, gpu: 7, cpu: 6)
    listing!("High end gaming PC", price: 140_000, gpu: 8, cpu: 7)

    result = recommend(games: [ @game.slug, hard.slug ], budget: "1000_1500")

    assert_equal [ "High end gaming PC" ], result.listings.map(&:title)
  end

  test "applies the budget and optional case and cooling filters" do
    listing!("White compact air", price: 110_000, gpu: 7, cpu: 6,
             specs: { "case_colour" => "White", "case_form_factor" => "Mini-Tower",
                      "cpu_cooler_type" => "Air" })
    listing!("Black mid AIO", price: 112_000, gpu: 7, cpu: 6,
             specs: { "case_colour" => "Black", "case_form_factor" => "Mid-Tower",
                      "cpu_cooler_type" => "AIO" })
    listing!("Over budget", price: 220_000, gpu: 9, cpu: 8,
             specs: { "case_colour" => "White", "case_form_factor" => "Mini-Tower",
                      "cpu_cooler_type" => "Air" })

    result = recommend(budget: "1000_1500", case_colour: "White",
                       case_size: "compact", cooling: "air")

    assert_equal [ "White compact air" ], result.listings.map(&:title)
  end

  test "ranks cheapest first with a small bonus for a matching vibe" do
    cheaper = listing!("Cheaper", price: 110_000, gpu: 7, cpu: 6)
    tagged = listing!("Tagged", price: 113_000, gpu: 7, cpu: 6)
    ListingTag.create!(listing: tagged, tag: @vibe)

    untagged_result = recommend(budget: "1000_1500")
    assert_equal [ cheaper.id, tagged.id ], untagged_result.listings.map(&:id)

    tagged_result = recommend(budget: "1000_1500", vibe: @vibe.slug)
    assert_equal [ tagged.id, cheaper.id ], tagged_result.listings.map(&:id)
  end

  test "paginates and reports the total count" do
    14.times { |index| listing!("Gaming PC #{index}", price: 110_000 + index, gpu: 7, cpu: 6) }

    first = recommend(budget: "1000_1500", page: 1)
    second = recommend(budget: "1000_1500", page: 2)

    assert_equal 12, first.listings.size
    assert_equal 14, first.total_count
    assert_equal 2, second.listings.size
  end

  test "returns an empty result when the gaming category is missing" do
    @gaming.destroy!

    result = recommend(budget: "1000_1500")

    assert_predicate result, :empty?
    assert_equal 0, result.total_count
  end

  private

  def listing!(title, price:, gpu:, cpu:, specs: {})
    record = create_listing!(store: stores(:confirmed_store), seller: users(:confirmed),
                             title: title, category: @gaming, price_cents: price,
                             specs: specs)
    record.update_columns(gpu_tier: gpu, cpu_tier: cpu)
    record
  end

  def recommend(**params)
    criteria = PcFinder::Criteria.new({ "games" => [ @game.slug ], "resolution" => "1440p",
                                        "fps" => "144" }.merge(params.stringify_keys))
    PcFinder::Recommend.new(criteria, page: params[:page]).call
  end
end
