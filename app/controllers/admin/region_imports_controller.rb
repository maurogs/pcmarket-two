# frozen_string_literal: true

module Admin
  class RegionImportsController < AdminOnlyController
    def create
      country = Country.find_by(code: params[:country_id].to_s.upcase) || Country.find(params[:country_id])
      authorize Region, :import?, policy_class: Admin::RegionPolicy

      result = Regions::Import.new(country: country, text: params[:text]).call
      audit!(action: "region.imported", auditable: country,
             changes: { created: result.created, updated: result.updated,
                        skipped: result.skipped })
      redirect_to admin_country_regions_path(country),
                  notice: t("admin.regions.flash.imported", created: result.created,
                                                            updated: result.updated,
                                                            skipped: result.skipped)
    end
  end
end
