# frozen_string_literal: true

module PcFinderHelper
  def pc_finder_expected_performances(listing, criteria)
    criteria.games.map do |game|
      PcFinder::ExpectedPerformance.new(listing: listing, game: game,
                                        resolution: criteria.resolution).call
    end
  end

  def pc_finder_resolution_label(resolution)
    t("pc_finder.resolutions.#{resolution}", default: resolution)
  end

  def pc_finder_budget_label(budget)
    return t("pc_finder.answers.none") if budget.blank?

    t("pc_finder.budgets.#{budget}")
  end

  def pc_finder_case_size_label(size)
    return t("pc_finder.answers.none") if size.blank?

    t("pc_finder.case_sizes.#{size}")
  end

  def pc_finder_cooling_label(cooling)
    return t("pc_finder.answers.none") if cooling.blank?

    t("pc_finder.cooling_options.#{cooling}")
  end

  def pc_finder_vibe_label(vibe)
    tag = Tag.seller_tags.find_by(slug: vibe)
    tag&.name || t("pc_finder.answers.none")
  end

  # Removes one answer from the shareable query string so chips can tweak it.
  def pc_finder_without(criteria, *keys)
    params = criteria.params.except("locale", "page", *keys.map(&:to_s))
    pc_finder_path(params)
  end
end
