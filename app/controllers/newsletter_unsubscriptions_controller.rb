# frozen_string_literal: true

class NewsletterUnsubscriptionsController < ApplicationController
  def show
    @subscription = NewsletterSubscription.find_by!(token: params[:token])
    @subscription.unsubscribe!
  end
end
