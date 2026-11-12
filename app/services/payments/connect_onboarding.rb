# frozen_string_literal: true

module Payments
  # Creates (or reuses) the seller's Stripe Express account and returns a fresh
  # account onboarding link.
  class ConnectOnboarding
    Error = Class.new(StandardError)

    def initialize(store:, refresh_url:, return_url:)
      @store = store
      @refresh_url = refresh_url
      @return_url = return_url
    end

    def call
      account_id = ensure_account
      link = Stripe::AccountLink.create(
        account: account_id,
        type: "account_onboarding",
        refresh_url: @refresh_url,
        return_url: @return_url
      )
      link.url
    rescue Stripe::StripeError => e
      raise Error, e.message
    end

    private

    def ensure_account
      return @store.stripe_account_id if @store.stripe_account_id.present?

      account = Stripe::Account.create(
        {
          type: "express",
          country: "ES",
          email: @store.user.email,
          business_type: @store.business? ? "company" : "individual",
          capabilities: { transfers: { requested: true } },
          metadata: { store_id: @store.id }
        }
      )

      @store.update!(
        stripe_account_id: account.id,
        requirements: account_requirements(account)
      )
      account.id
    end

    def account_requirements(account)
      requirements = account.requirements
      requirements.respond_to?(:to_hash) ? requirements.to_hash : {}
    end
  end
end
