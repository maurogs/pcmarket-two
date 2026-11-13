# frozen_string_literal: true

module PcFinder
  # Normalises the shareable quiz query string. Invalid values are ignored so
  # a malformed URL never raises; the quiz falls back to its defaults.
  class Criteria
    RESOLUTIONS = %w[1080p 1440p 4k].freeze
    FPS_BANDS = %w[60 144 240].freeze
    MAX_GAMES = 3

    BUDGETS = {
      "under_600" => 0...60_000,
      "600_1000" => 60_000..100_000,
      "1000_1500" => 100_000..150_000,
      "1500_2500" => 150_000..250_000,
      "2500_plus" => 250_000..
    }.freeze

    CASE_SIZES = {
      "compact" => %w[Mini-Tower Small\ form\ factor],
      "mid" => [ "Mid-Tower" ],
      "full" => [ "Full-Tower" ]
    }.freeze

    CASE_COLOURS = %w[Black White Silver Grey].freeze

    COOLING = {
      "air" => [ "Air" ],
      "aio" => [ "AIO" ]
    }.freeze

    VIBES = %w[minimalist rgb anime whiteout retro].freeze

    attr_reader :games, :resolution, :fps, :budget, :case_colour, :case_size,
                :cooling, :vibe

    def initialize(params = {})
      @params = params.respond_to?(:to_h) ? params.to_h.stringify_keys : {}
      @games = load_games
      @resolution = value_in("resolution", RESOLUTIONS) || "1440p"
      @fps = value_in("fps", FPS_BANDS) || "144"
      @budget = value_in("budget", BUDGETS.keys)
      @case_colour = value_in("case_colour", CASE_COLOURS)
      @case_size = value_in("case_size", CASE_SIZES.keys)
      @cooling = value_in("cooling", COOLING.keys)
      @vibe = value_in("vibe", VIBES)
    end

    def params
      @params
    end

    def game_slugs
      games.map(&:slug)
    end

    def budget_range
      return if budget.blank?

      BUDGETS.fetch(budget)
    end

    def case_form_factors
      CASE_SIZES.fetch(case_size, [])
    end

    def cooler_types
      COOLING.fetch(cooling, [])
    end

    # The preset "best PCs for <game>" URL carries only the game.
    def preset_game
      return if games.size != 1

      games.first
    end

    def preset?
      preset_game.present? &&
        (params.keys - %w[game locale]).empty?
    end

    def selected?
      (params.keys - %w[locale page]).any?
    end

    def max_gpu_tier
      games.map { |game| game.gpu_requirement(resolution, fps) }.max.to_i
    end

    def max_cpu_tier
      games.map { |game| game.cpu_requirement(resolution, fps) }.max.to_i
    end

    def to_h
      {
        games: game_slugs,
        resolution: resolution,
        fps: fps,
        budget: budget,
        case_colour: case_colour,
        case_size: case_size,
        cooling: cooling,
        vibe: vibe
      }
    end

    private

    def value_in(key, allowed)
      candidate = @params[key].to_s
      allowed.include?(candidate) ? candidate : nil
    end

    def load_games
      slugs = Array(@params["games"]).map(&:to_s).reject(&:blank?)
      slugs.concat(Array(@params["game"]).map(&:to_s).reject(&:blank?))
      slugs = slugs.uniq.first(MAX_GAMES)
      return [] if slugs.empty?

      by_slug = Game.active.where(slug: slugs).index_by(&:slug)
      slugs.filter_map { |slug| by_slug[slug] }
    end
  end
end
