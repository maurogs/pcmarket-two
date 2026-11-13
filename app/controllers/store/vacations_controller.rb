# frozen_string_literal: true

# Seller-facing vacation mode settings.
class Store::VacationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_store

  def show
    authorize @store, :update?
  end

  def update
    authorize @store, :update?

    if Stores::SetVacation.new(store: @store, attributes: vacation_params).call
      redirect_to store_vacation_path,
                  notice: t("stores.vacation.flash.updated")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_store
    @store = current_user.store
    redirect_to new_store_path if @store.blank?
  end

  def vacation_params
    params.require(:store).permit(:vacation_mode, :vacation_message, :vacation_until)
  end
end
