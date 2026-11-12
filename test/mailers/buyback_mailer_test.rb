# frozen_string_literal: true

require "test_helper"

class BuybackMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:confirmed)
    @user.update!(locale: "de")
    price = BuybackPrice.create!(component_type: :gpu, component_model: "RTX 4070",
                                 base_offer_cents: 30_000)
    quote = BuybackQuote.create!(buyback_price: price, component_type: :gpu,
                                 component_model: "RTX 4070", condition: "good",
                                 offer_cents: 25_500, expires_at: 7.days.from_now)
    @request = BuybackRequest.create!(
      buyback_quote: quote, user: @user, component_type: :gpu,
      component_model: "RTX 4070", condition: "good", offer_cents: 25_500,
      iban: "ES9121000418450200051332", full_name: "Mauro Ruiz",
      line1: "Calle Mayor 1", city: "Madrid", postal_code: "28001",
      country_code: "ES"
    )
    @request.accept!
  end

  test "renders each step in the user locale with the trade-in link" do
    email = BuybackMailer.status_update(@request, "label_sent")

    assert_equal [ @user.email ], email.to
    assert_equal I18n.t("buyback_mailer.events.label_sent.subject",
                        reference: @request.reference, locale: :de), email.subject
    assert_includes email.text_part.body.to_s, @request.reference
    assert_includes email.text_part.body.to_s, "/de/sell-to-us/trade-ins/"
    assert_includes email.html_part.body.to_s,
                    I18n.t("buyback_mailer.events.label_sent.title",
                           reference: @request.reference, locale: :de)
  end

  test "uses the revised amount in the offer email" do
    @request.update!(revised_offer_cents: 21_000, status: "offer_revised")
    email = BuybackMailer.status_update(@request, "offer_revised")

    assert_includes email.text_part.body.to_s, "210,00"
    assert_equal I18n.t("buyback_mailer.events.offer_revised.subject",
                        reference: @request.reference, locale: :de), email.subject
  end
end
