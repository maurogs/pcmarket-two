# frozen_string_literal: true

module Admin
  class GamesController < AdminOnlyController
    before_action :set_game, only: %i[edit update destroy]

    def index
      authorize Game, :index?, policy_class: Admin::GamePolicy
      @games = Game.ordered
    end

    def new
      @game = Game.new(active: true, position: next_position)
      authorize @game, policy_class: Admin::GamePolicy
    end

    def create
      @game = Game.new(game_params)
      @game.position = next_position if @game.position.to_i.zero?
      authorize @game, policy_class: Admin::GamePolicy

      if @game.save
        audit!(action: "game.created", auditable: @game, changes: @game.saved_changes)
        redirect_to admin_games_path, notice: t("admin.games.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @game, policy_class: Admin::GamePolicy
    end

    def update
      authorize @game, policy_class: Admin::GamePolicy

      if @game.update(game_params)
        audit!(action: "game.updated", auditable: @game,
               changes: @game.saved_changes.except("updated_at"))
        redirect_to admin_games_path, notice: t("admin.games.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @game, policy_class: Admin::GamePolicy
      @game.destroy!
      audit!(action: "game.destroyed", auditable: @game)
      redirect_to admin_games_path, notice: t("admin.games.flash.destroyed")
    end

    private

    def set_game
      @game = Game.find(params[:id])
    end

    def game_params
      permitted = params.require(:game).permit(:name, :slug, :position, :active, :cover,
                                               min_gpu_tier: {}, min_cpu_tier: {})
      permitted[:min_gpu_tier] = compact_tiers(permitted[:min_gpu_tier])
      permitted[:min_cpu_tier] = compact_tiers(permitted[:min_cpu_tier])
      permitted
    end

    def compact_tiers(value)
      (value || {}).to_h.filter_map do |key, tier|
        next if tier.blank?

        [ key, tier.to_i ]
      end.to_h
    end

    def next_position
      (Game.maximum(:position) || 0) + 1
    end
  end
end
