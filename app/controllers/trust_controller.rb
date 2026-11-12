# frozen_string_literal: true

class TrustController < ApplicationController
  def show
    @stats = TrustStats.current
    @protection_days = Setting.get(:buyer_protection_days, 2)
    @support_email = Setting.get(:support_email, "support@pcmarket.example")
  end
end
