# frozen_string_literal: true

class StoresController < ApplicationController
  before_action :authenticate_user!
  before_action :set_store
  before_action :require_store, only: %i[edit update]

  def new
    return redirect_to edit_store_path if @store.persisted?

    authorize @store
    load_regions
  end

  def create
    authorize @store
    @store.assign_attributes(store_params)

    if save_store
      redirect_to new_sell_listing_path, notice: t("stores.flash.created")
    else
      load_regions
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @store
    load_regions
  end

  def update
    authorize @store
    @store.assign_attributes(store_params)

    if save_store
      redirect_to edit_store_path, notice: t("stores.flash.updated")
    else
      load_regions
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_store
    @store = current_user.store || current_user.build_store(country_code: "ES")
  end

  def require_store
    redirect_to new_store_path unless @store.persisted?
  end

  def save_store
    @store.save(context: :onboarding)
  end

  def load_regions
    @regions = Region.where(country_code: "ES").order(:position, :name)
  end

  def store_params
    params.require(:store).permit(
      :kind, :name, :description, :logo, :region_id, :city, :country_code,
      :legal_name, :tax_id, :address_line, :postal_code, :phone, :website
    )
  end
end
