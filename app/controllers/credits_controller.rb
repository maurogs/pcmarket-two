# frozen_string_literal: true

class CreditsController < ApplicationController
  def show
    @credits = Demo::ImageCredits.entries
  end
end
