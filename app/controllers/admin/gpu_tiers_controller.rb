# frozen_string_literal: true

module Admin
  class GpuTiersController < AdminOnlyController
    before_action :set_tier, only: %i[edit update destroy]

    def index
      authorize GpuTier, :index?, policy_class: Admin::GpuTierPolicy
      @tiers = GpuTier.ordered
    end

    def new
      @tier = GpuTier.new(active: true, tier: 5, position: next_position)
      authorize @tier, policy_class: Admin::GpuTierPolicy
    end

    def create
      @tier = GpuTier.new(tier_params)
      @tier.position = next_position if @tier.position.to_i.zero?
      authorize @tier, policy_class: Admin::GpuTierPolicy

      if @tier.save
        audit!(action: "gpu_tier.created", auditable: @tier, changes: @tier.saved_changes)
        redirect_to admin_gpu_tiers_path, notice: t("admin.gpu_tiers.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @tier, policy_class: Admin::GpuTierPolicy
    end

    def update
      authorize @tier, policy_class: Admin::GpuTierPolicy

      if @tier.update(tier_params)
        audit!(action: "gpu_tier.updated", auditable: @tier,
               changes: @tier.saved_changes.except("updated_at"))
        redirect_to admin_gpu_tiers_path, notice: t("admin.gpu_tiers.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @tier, policy_class: Admin::GpuTierPolicy
      @tier.destroy!
      audit!(action: "gpu_tier.destroyed", auditable: @tier)
      redirect_to admin_gpu_tiers_path, notice: t("admin.gpu_tiers.flash.destroyed")
    end

    private

    def set_tier
      @tier = GpuTier.find(params[:id])
    end

    def tier_params
      params.require(:gpu_tier).permit(:pattern, :tier, :position, :active)
    end

    def next_position
      (GpuTier.maximum(:position) || 0) + 1
    end
  end
end
