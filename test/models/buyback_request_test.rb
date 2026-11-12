# frozen_string_literal: true

require "test_helper"

class BuybackRequestTest < ActiveSupport::TestCase
  setup do
    @price = BuybackPrice.create!(component_type: :gpu, component_model: "RTX 4070",
                                  base_offer_cents: 30_000)
    @quote = BuybackQuote.create!(
      buyback_price: @price, component_type: :gpu, component_model: "RTX 4070",
      condition: "good", answers: { "powers_on" => "1" }, offer_cents: 25_500,
      expires_at: 7.days.from_now
    )
  end

  test "creates a quoted request with an encrypted IBAN and reference" do
    request = build_request

    assert_predicate request, :quoted?
    assert_match(/\APCM-T-\d{4}-[0-9A-F]{6}\z/, request.reference)
    assert_equal "1332", request.iban_last4
    assert_equal "•••• 1332", request.masked_iban
    assert_equal "ES9121000418450200051332", request.iban

    raw = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql([ "SELECT iban FROM buyback_requests WHERE id = ?", request.id ])
    )
    assert_not_includes raw.to_s, "ES9121000418450200051332"
    assert raw.to_s.start_with?("{")
    assert_operator raw.to_s.length, :>, 40
  end

  test "rejects invalid IBANs" do
    request = BuybackRequest.new(
      buyback_quote: @quote, user: users(:confirmed), component_type: :gpu,
      component_model: "RTX 4070", condition: "good", offer_cents: 25_500,
      iban: "ES9121000418450200051333", full_name: "Mauro Ruiz",
      line1: "Calle Mayor 1", city: "Madrid", postal_code: "28001",
      country_code: "ES"
    )

    assert_not request.valid?
    assert_includes request.errors[:iban], I18n.t("errors.messages.invalid_iban")
  end

  test "runs the quoted to paid state machine" do
    request = build_request

    assert_not request.may_send_label?

    assert request.accept!
    assert_predicate request, :accepted?
    assert_not_nil request.accepted_at

    assert_not request.send_label!
    request.tracking_number = "TRACK123"
    assert request.send_label!
    assert_predicate request, :label_sent?

    assert request.receive!
    assert request.mark_inspected!
    assert_predicate request, :inspected?

    assert_not request.revise_offer!
    request.revised_offer_cents = 20_000
    assert request.revise_offer!
    assert_predicate request, :offer_revised?

    assert request.accept_revision!
    assert request.mark_paid!
    assert_predicate request, :paid?
    assert_equal 20_000, request.final_offer_cents
  end

  test "supports rejection and return paths" do
    rejected = build_request
    rejected.accept!
    rejected.tracking_number = "TRACK"
    rejected.send_label!
    rejected.receive!
    rejected.mark_inspected!
    assert rejected.reject!
    assert_predicate rejected, :rejected?

    returned = build_request
    returned.accept!
    returned.tracking_number = "TRACK"
    returned.send_label!
    returned.receive!
    returned.mark_inspected!
    assert returned.return_to_sender!
    assert_predicate returned, :returned?
  end

  test "builds a timeline with completed steps" do
    request = build_request
    request.accept!
    request.tracking_number = "TRACK"
    request.send_label!

    timeline = request.timeline
    assert_equal %i[done done done pending pending].first(3), timeline.first(3).map { |entry| entry[:state] }
    assert_equal "quoted", timeline.first[:key]
  end

  private

  def build_request(iban: "ES91 2100 0418 4502 0005 1332")
    BuybackRequest.create!(
      buyback_quote: @quote, user: users(:confirmed), component_type: :gpu,
      component_model: "RTX 4070", condition: "good", offer_cents: 25_500,
      iban: iban, full_name: "Mauro Ruiz", line1: "Calle Mayor 1",
      city: "Madrid", postal_code: "28001", country_code: "ES"
    )
  end
end
