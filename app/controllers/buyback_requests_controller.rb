# frozen_string_literal: true

class BuybackRequestsController < ApplicationController
  before_action :require_sell_to_us
  before_action :authenticate_user!

  def index
    authorize BuybackRequest, :index?
    @requests = current_user.buyback_requests.includes(:buyback_quote).recent
  end

  def show
    @request = current_user.buyback_requests.find(params[:id])
    authorize @request
  end

  def new
    authorize BuybackRequest, :new?
    @quote = BuybackQuote.find_by!(token: params[:quote_id])
    @request = BuybackRequest.new(country_code: "ES")
  end

  def create
    authorize BuybackRequest, :create?
    quote = BuybackQuote.find_by!(token: params[:quote_id])
    result = BuybackRequests::Create.new(quote: quote, user: current_user,
                                         attributes: request_params).call

    if result.success?
      redirect_to buyback_request_path(result.request),
                  notice: t("buyback.flash.request_created", reference: result.request.reference)
    else
      @quote = quote
      @request = result.request || BuybackRequest.new(country_code: "ES")
      result.errors.each { |message| @request.errors.add(:base, message) } if @request.errors.empty?
      render :new, status: :unprocessable_entity
    end
  end

  private

  def request_params
    params.require(:buyback_request).permit(:iban, :full_name, :line1, :line2, :city,
                                            :postal_code, :country_code, :phone)
  end

  def require_sell_to_us
    require_feature!(:sell_to_us)
  end
end
