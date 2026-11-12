# frozen_string_literal: true

module Admin
  class CountriesController < AdminOnlyController
    before_action :set_country, only: %i[edit update]

    def index
      authorize Country, :index?, policy_class: Admin::CountryPolicy

      @countries = Country.order(:position, :code).includes(:regions)
    end

    def edit
      authorize @country, policy_class: Admin::CountryPolicy
    end

    def update
      authorize @country, policy_class: Admin::CountryPolicy

      if @country.update(country_params)
        audit!(action: "country.updated", auditable: @country,
               changes: @country.saved_changes.except("updated_at"))
        redirect_to admin_countries_path, notice: t("admin.countries.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_country
      @country = Country.find_by(code: params[:id].to_s.upcase) || Country.find(params[:id])
    end

    def country_params
      params.require(:country).permit(:default_locale, :currency, :vat_rate, :position, :active)
    end
  end
end
