# frozen_string_literal: true

class OffersController < ApplicationController
  before_action :ensure_offers_enabled
  before_action :authenticate_user!

  def create
    listing = Listing.friendly.find(params[:listing_id])
    offer = Offer.new(listing: listing, buyer: current_user)
    authorize offer

    result = Offers::Create.new(
      listing: listing,
      buyer: current_user,
      amount_cents: amount_cents_param,
      message: params[:message]
    ).call

    if result.success?
      redirect_to conversation_path(result.offer.conversation),
                  notice: t("offers.flash.created")
    else
      redirect_to listing_path(listing), alert: result.errors.first
    end
  end

  def update
    offer = Offer.find(params[:id])
    authorize offer

    result = Offers::Respond.new(
      offer: offer,
      actor: current_user,
      decision: params[:decision],
      amount_cents: amount_cents_param,
      message: params[:message]
    ).call

    if result.success?
      redirect_to conversation_path(offer.conversation),
                  notice: t("offers.flash.#{params[:decision]}")
    else
      redirect_to conversation_path(offer.conversation), alert: result.errors.first
    end
  end

  private

  def ensure_offers_enabled
    raise ActiveRecord::RecordNotFound unless Flipper.enabled?(:offers)
  end

  def amount_cents_param
    return if params[:amount].blank?

    (BigDecimal(params[:amount].to_s) * 100).round
  rescue ArgumentError, TypeError
    nil
  end
end
