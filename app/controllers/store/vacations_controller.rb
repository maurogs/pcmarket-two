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

    if @store.update(vacation_params)
      schedule_auto_off
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

  # The scheduled job checks the saved date again, so changing or clearing
  # the return date cannot switch vacation mode off early.
  def schedule_auto_off
    return unless @store.vacation_mode?
    return if @store.vacation_until.blank?

    Stores::VacationAutoOffJob
      .set(wait_until: @store.vacation_until.end_of_day)
      .perform_later(@store.id, @store.vacation_until)
  end
end
