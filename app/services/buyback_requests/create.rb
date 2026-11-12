# frozen_string_literal: true

module BuybackRequests
  # Creates the user's trade-in from an accepted quote. The request starts in
  # `quoted` (for the state machine contract) and immediately transitions to
  # `accepted` once the IBAN and shipping address validate.
  class Create
    Result = Struct.new(:request, :errors, keyword_init: true) do
      def success? = request&.persisted? && request&.accepted?
    end

    def initialize(quote:, user:, attributes:)
      @quote = quote
      @user = user
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      return Result.new(request: nil, errors: [ I18n.t("buyback.errors.quote_expired") ]) if @quote.expired?
      return Result.new(request: nil, errors: [ I18n.t("buyback.errors.quote_used") ]) if @quote.buyback_request.present?

      request = BuybackRequest.new(
        buyback_quote: @quote,
        user: @user,
        component_type: @quote.component_type,
        component_model: @quote.component_model,
        condition: @quote.condition,
        condition_answers: @quote.answers,
        offer_cents: @quote.offer_cents,
        iban: @attributes[:iban],
        full_name: @attributes[:full_name],
        line1: @attributes[:line1],
        line2: @attributes[:line2],
        city: @attributes[:city],
        postal_code: @attributes[:postal_code],
        country_code: @attributes[:country_code].presence || "ES",
        phone: @attributes[:phone],
        status: "quoted"
      )

      return Result.new(request: request, errors: request.errors.full_messages) unless request.save
      return Result.new(request: request, errors: [ I18n.t("buyback.errors.accept_failed") ]) unless request.accept!

      BuybackMailer.status_update(request, "accepted").deliver_later
      Result.new(request: request, errors: [])
    end
  end
end
