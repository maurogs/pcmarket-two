# frozen_string_literal: true

module PcFinder
  # Chooses the highest FPS band a listing can hold for one game at one
  # resolution. The result feeds the "Expected performance" line on cards.
  class ExpectedPerformance
    def initialize(listing:, game:, resolution:)
      @listing = listing
      @game = game
      @resolution = resolution.to_s
    end

    def fps
      Game::FPS_BANDS.sort.reverse.find { |band| meets?(band) }
    end

    def call
      return I18n.t("pc_finder.results.expected_unavailable", game: @game.name) if fps.nil?

      I18n.t("pc_finder.results.expected", game: @game.name, fps: fps,
                                          resolution: resolution_label)
    end

    private

    def meets?(band)
      @listing.gpu_tier.to_i >= @game.gpu_requirement(@resolution, band) &&
        @listing.cpu_tier.to_i >= @game.cpu_requirement(@resolution, band)
    end

    def resolution_label
      I18n.t("pc_finder.resolutions.#{@resolution}", default: @resolution)
    end
  end
end
