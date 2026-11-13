# frozen_string_literal: true

module Account
  class AddressesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_address, only: %i[edit update destroy]
    before_action :load_regions, only: %i[new create edit update]

    def index
      authorize Address
      @addresses = policy_scope(Address).default_first
    end

    def new
      @address = current_user.addresses.build(country_code: "ES",
                                              default: !current_user.addresses.exists?)
      authorize @address
    end

    def create
      @address = current_user.addresses.build(address_params)
      authorize @address

      if @address.save
        redirect_to account_addresses_path,
                    notice: t("account.addresses.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @address
    end

    def update
      authorize @address

      if @address.update(address_params)
        redirect_to account_addresses_path,
                    notice: t("account.addresses.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @address
      @address.destroy!
      redirect_to account_addresses_path,
                  notice: t("account.addresses.flash.destroyed")
    end

    private

    def set_address
      @address = current_user.addresses.find(params[:id])
    end

    def load_regions
      @regions = Region.where(country_code: "ES").order(:position, :name)
    end

    def address_params
      params.require(:address).permit(
        :full_name, :line1, :line2, :city, :region_id, :postal_code,
        :country_code, :phone, :default
      )
    end
  end
end
