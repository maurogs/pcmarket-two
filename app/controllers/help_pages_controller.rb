# frozen_string_literal: true

class HelpPagesController < ApplicationController
  SLUGS = %w[about how-it-works how-to-sell seller-fees shipping returns].freeze

  def index
  end

  def show
    @slug = params[:slug].to_s
    raise ActiveRecord::RecordNotFound unless SLUGS.include?(@slug)
  end
end
