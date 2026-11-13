# frozen_string_literal: true

class PcFindersController < ApplicationController
  def show
    authorize :pc_finder, :show?

    @criteria = PcFinder::Criteria.new(criteria_params)
    @result = PcFinder::Recommend.new(@criteria, page: params[:page]).call
    @landing = PcFinder::Landing.new
    @games = Game.active.ordered.includes(cover_attachment: :blob).to_a

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("pc_finder_results_list",
                              partial: "pc_finders/results",
                              locals: { result: @result }),
          turbo_stream.replace("pc_finder_load_more",
                               partial: "pc_finders/load_more",
                               locals: { result: @result })
        ]
      end
    end
  end

  private

  def criteria_params
    params.permit(:game, :resolution, :fps, :budget, :case_colour,
                  :case_size, :cooling, :vibe, :page, games: []).to_h
  end
end
