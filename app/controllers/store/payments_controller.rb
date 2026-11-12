# frozen_string_literal: true

# Seller-facing Stripe Connect onboarding and payout status.
class Store::PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :block_impersonation
  before_action :set_store

  def show
    authorize @store, :update?
  end

  def create
    authorize @store, :update?

    url = Payments::ConnectOnboarding.new(
      store: @store,
      refresh_url: store_payment_url,
      return_url: store_payment_url
    ).call

    redirect_to url, allow_other_host: true
  rescue Payments::ConnectOnboarding::Error
    redirect_to store_payment_path, alert: t("store_payments.errors.onboarding_failed")
  end

  private

  def block_impersonation
    return unless impersonating?

    redirect_to root_path, alert: t("admin.impersonation.payment_blocked")
  end

  def set_store
    @store = current_user.store
    redirect_to new_store_path if @store.blank?
  end
end
