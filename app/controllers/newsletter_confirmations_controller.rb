# frozen_string_literal: true

class NewsletterConfirmationsController < ApplicationController
  def show
    @subscription = NewsletterSubscription.find_by!(token: params[:token])
    @subscription.confirm!
  end
end
