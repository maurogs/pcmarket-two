# frozen_string_literal: true

class ErrorsController < ApplicationController
  skip_before_action :enforce_maintenance_mode
  skip_before_action :merge_guest_cart
  skip_after_action :verify_authorized, raise: false

  STATUSES = {
    "404" => :not_found,
    "422" => :unprocessable_entity,
    "500" => :internal_server_error
  }.freeze

  def show
    @status = STATUSES.fetch(params[:code].to_s, :internal_server_error)
    @code = STATUSES.key(@status)
    response.headers["X-Robots-Tag"] = "noindex"
    response.headers["Cache-Control"] = "no-store"

    respond_to do |format|
      format.html { render :show, status: @status, layout: "error" }
      format.any { head @status }
    end
  end
end
