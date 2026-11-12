# frozen_string_literal: true

class BuybackQuotePolicy < ApplicationPolicy
  def new? = true
  def create? = true
  def show? = true
end
