# frozen_string_literal: true

require "test_helper"

class PcFinderExpectedPerformanceTest < ActiveSupport::TestCase
  setup do
    @game = Game.create!(
      name: "Fortnite", slug: "fortnite", position: 1, active: true,
      min_gpu_tier: { "1440p_60" => 4, "1440p_144" => 6, "1440p_240" => 9 },
      min_cpu_tier: { "1440p_60" => 3, "1440p_144" => 5, "1440p_240" => 8 }
    )
    @listing = create_listing!(store: stores(:confirmed_store), seller: users(:confirmed),
                               specs: { "gpu_model" => "RTX 4070", "cpu_model" => "Ryzen 5 5600" })
    @listing.update_columns(gpu_tier: 7, cpu_tier: 6)
  end

  test "reports the highest fps band the listing can hold" do
    text = PcFinder::ExpectedPerformance.new(listing: @listing, game: @game,
                                             resolution: "1440p").call

    assert_equal I18n.t("pc_finder.results.expected", game: "Fortnite", fps: 144,
                                                       resolution: "1440p"), text
    assert_includes text, "144 FPS"
  end

  test "falls back to a playable message below 60 fps" do
    @listing.update_columns(gpu_tier: 1, cpu_tier: 1)

    text = PcFinder::ExpectedPerformance.new(listing: @listing, game: @game,
                                             resolution: "1440p").call

    assert_equal I18n.t("pc_finder.results.expected_unavailable", game: "Fortnite"), text
  end

  test "criteria fall back to the nearest lower band and ignore invalid params" do
    @game.update!(min_gpu_tier: { "1440p_60" => 4 }, min_cpu_tier: { "1440p_60" => 3 })

    criteria = PcFinder::Criteria.new("games" => [ @game.slug ], "resolution" => "bogus",
                                      "budget" => "9999", "vibe" => "nope")

    assert_equal "1440p", criteria.resolution
    assert_nil criteria.budget
    assert_nil criteria.vibe
    assert_equal 4, criteria.max_gpu_tier
    assert_equal 3, criteria.max_cpu_tier
  end
end
