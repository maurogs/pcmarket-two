# frozen_string_literal: true

require "test_helper"

class AdminPcFinderTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "creates, edits and deletes a game with tier requirements" do
    get admin_games_path(locale: :en)
    assert_response :success

    post admin_games_path(locale: :en), params: {
      game: { name: "Fortnite", slug: "fortnite", position: 1, active: "1",
              min_gpu_tier: { "1080p_60" => "3", "1440p_144" => "6" },
              min_cpu_tier: { "1080p_60" => "2", "1440p_144" => "5" } }
    }

    game = Game.find_by!(slug: "fortnite")
    assert_redirected_to admin_games_path(locale: :en)
    assert_equal 6, game.min_gpu_tier["1440p_144"]

    patch admin_game_path(game, locale: :en), params: {
      game: { name: "Fortnite Battle Royale", min_gpu_tier: { "1440p_144" => "7" } }
    }
    assert_redirected_to admin_games_path(locale: :en)
    assert_equal "Fortnite Battle Royale", game.reload.name
    assert_equal 7, game.min_gpu_tier["1440p_144"]

    assert_difference "Game.count", -1 do
      delete admin_game_path(game, locale: :en)
    end
  end

  test "manages GPU and CPU tier patterns" do
    post admin_gpu_tiers_path(locale: :en), params: {
      gpu_tier: { pattern: "RTX 4070", tier: 7, position: 1, active: "1" }
    }
    tier = GpuTier.find_by!(pattern: "rtx 4070")
    assert_redirected_to admin_gpu_tiers_path(locale: :en)
    assert_equal 7, tier.tier

    patch admin_gpu_tier_path(tier, locale: :en), params: {
      gpu_tier: { pattern: "RTX 4070", tier: 8, position: 2, active: "0" }
    }
    assert_equal 8, tier.reload.tier
    assert_not_predicate tier, :active?

    post admin_cpu_tiers_path(locale: :en), params: {
      cpu_tier: { pattern: "Ryzen 5 5600", tier: 5, position: 1, active: "1" }
    }
    cpu = CpuTier.find_by!(pattern: "ryzen 5 5600")
    assert_equal 5, cpu.tier
  end

  test "moderators cannot manage PC Finder data" do
    sign_in users(:moderator)

    get admin_games_path(locale: :en)
    assert_response :not_found

    get admin_gpu_tiers_path(locale: :en)
    assert_response :not_found
  end
end
