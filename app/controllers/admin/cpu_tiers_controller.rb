# frozen_string_literal: true

module Admin
  class CpuTiersController < AdminOnlyController
    before_action :set_tier, only: %i[edit update destroy]

    def index
      authorize CpuTier, :index?, policy_class: Admin::CpuTierPolicy
      @tiers = CpuTier.ordered
    end

    def new
      @tier = CpuTier.new(active: true, tier: 5, position: next_position)
      authorize @tier, policy_class: Admin::CpuTierPolicy
    end

    def create
      @tier = CpuTier.new(tier_params)
      @tier.position = next_position if @tier.position.to_i.zero?
      authorize @tier, policy_class: Admin::CpuTierPolicy

      if @tier.save
        audit!(action: "cpu_tier.created", auditable: @tier, changes: @tier.saved_changes)
        redirect_to admin_cpu_tiers_path, notice: t("admin.cpu_tiers.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @tier, policy_class: Admin::CpuTierPolicy
    end

    def update
      authorize @tier, policy_class: Admin::CpuTierPolicy

      if @tier.update(tier_params)
        audit!(action: "cpu_tier.updated", auditable: @tier,
               changes: @tier.saved_changes.except("updated_at"))
        redirect_to admin_cpu_tiers_path, notice: t("admin.cpu_tiers.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @tier, policy_class: Admin::CpuTierPolicy
      @tier.destroy!
      audit!(action: "cpu_tier.destroyed", auditable: @tier)
      redirect_to admin_cpu_tiers_path, notice: t("admin.cpu_tiers.flash.destroyed")
    end

    private

    def set_tier
      @tier = CpuTier.find(params[:id])
    end

    def tier_params
      params.require(:cpu_tier).permit(:pattern, :tier, :position, :active)
    end

    def next_position
      (CpuTier.maximum(:position) || 0) + 1
    end
  end
end
