# frozen_string_literal: true

module Admin
  class RegionsController < AdminOnlyController
    before_action :set_country
    before_action :set_region, only: %i[edit update destroy]

    def index
      authorize Region, :index?, policy_class: Admin::RegionPolicy

      @regions = @country.regions.order(:position, :name)
      @launch_checks = @country.launch_checks
    end

    def new
      @region = @country.regions.new(position: next_position)
      authorize @region, policy_class: Admin::RegionPolicy
    end

    def create
      @region = @country.regions.new(region_params)
      @region.position = next_position if @region.position.zero?
      authorize @region, policy_class: Admin::RegionPolicy

      if @region.save
        audit!(action: "region.created", auditable: @region, changes: @region.saved_changes)
        redirect_to admin_country_regions_path(@country),
                    notice: t("admin.regions.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @region, policy_class: Admin::RegionPolicy
    end

    def update
      authorize @region, policy_class: Admin::RegionPolicy

      if @region.update(region_params)
        audit!(action: "region.updated", auditable: @region,
               changes: @region.saved_changes.except("updated_at"))
        redirect_to admin_country_regions_path(@country),
                    notice: t("admin.regions.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @region, policy_class: Admin::RegionPolicy

      if @region.listings.exists?
        redirect_to admin_country_regions_path(@country),
                    alert: t("admin.regions.flash.in_use")
        return
      end

      @region.destroy!
      audit!(action: "region.destroyed", auditable: @region)
      redirect_to admin_country_regions_path(@country),
                  notice: t("admin.regions.flash.destroyed")
    end

    private

    def set_country
      @country = Country.find_by(code: params[:country_id].to_s.upcase) || Country.find(params[:country_id])
    end

    def set_region
      @region = @country.regions.find(params[:id])
    end

    def region_params
      params.require(:region).permit(:code, :name, :position)
    end

    def next_position
      (@country.regions.maximum(:position) || 0) + 1
    end
  end
end
