# frozen_string_literal: true

class RobotsController < ApplicationController
  skip_before_action :enforce_maintenance_mode, :merge_guest_cart
  skip_after_action :verify_authorized, raise: false

  def show
    @noindex = ENV["NOINDEX"] == "1"
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    response.headers["Cache-Control"] = "public, max-age=3600"
    render :show, formats: :text, layout: false
  end
end
