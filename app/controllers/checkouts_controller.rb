# frozen_string_literal: true

class CheckoutsController < ApplicationController
  before_action :load_cart

  def new
    authorize Checkout, :new?
    redirect_to cart_path, alert: t("checkout.errors.empty_cart") if @groups.empty?

    @checkout = Checkout.new(email: current_user&.email)
    @address = Address.new(country_code: "ES",
                           full_name: current_user&.display_name,
                           phone: current_user&.phone)
    @addresses = current_user ? current_user.addresses.default_first : Address.none
  end

  def create
    authorize Checkout, :create?

    result = Checkouts::Start.new(cart: @cart,
                                  buyer: current_user,
                                  params: checkout_params,
                                  gateway: gateway).call

    if result.success?
      Checkouts::Complete.new(checkout: result.checkout, cart: @cart).call
      session[:last_checkout_id] = result.checkout.id
      redirect_to checkout_path, notice: t("checkout.flash.completed")
    else
      @errors = result.errors
      @checkout = result.checkout || Checkout.new(email: checkout_params[:email])
      @address = submitted_address
      @addresses = current_user ? current_user.addresses.default_first : Address.none
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @checkout = last_checkout
    return redirect_to orders_path, alert: t("checkout.errors.not_found") if @checkout.nil?

    authorize @checkout
    @orders = @checkout.orders.includes(:store, items: :listing).recent_first
  end

  private

  def load_cart
    @cart = current_cart
    @buy_now_listing_id = (params[:buy_now] || params[:buy_now_listing_id]).presence
    @groups = @cart.persisted? ? @cart.groups(listing_id: @buy_now_listing_id) : []
    @subtotal_cents = @groups.sum(&:subtotal_cents)
    @shipping_cents = @groups.sum(&:shipping_cents)
  end

  def last_checkout
    id = session[:last_checkout_id]
    return Checkout.find_by(id: id) if id.present?

    return if current_user.blank?

    current_user.checkouts.where(status: "paid").recent_first.first
  end

  def submitted_address
    raw = params[:address]
    return Address.new(country_code: "ES") if raw.blank?

    Address.new(raw.permit(:full_name, :line1, :line2, :city, :region_id,
                           :postal_code, :country_code, :phone))
  end

  def gateway
    Payments.gateway(failure: params[:payment_result] == "failure")
  end

  def checkout_params
    params.permit(
      :email, :address_id, :save_address, :terms_accepted, :idempotency_key,
      :buy_now_listing_id,
      address: %i[full_name line1 line2 city region_id postal_code country_code phone],
      fulfilment: {}
    )
  end
end
