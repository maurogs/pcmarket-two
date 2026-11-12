# frozen_string_literal: true

require "test_helper"

class SellToUsTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable(:sell_to_us)
    ActionMailer::Base.deliveries.clear
    @gpu_price = BuybackPrice.create!(component_type: :gpu, component_model: "RTX 4070",
                                      base_offer_cents: 30_000)
    @cpu_price = BuybackPrice.create!(component_type: :cpu, component_model: "Ryzen 5 5600",
                                      base_offer_cents: 8_000)
  end

  teardown do
    Flipper.disable(:sell_to_us)
  end

  test "every route is a 404 while the flag is off" do
    Flipper.disable(:sell_to_us)

    get sell_to_us_path(locale: :en)
    assert_response :not_found

    get new_buyback_quote_path(locale: :en)
    assert_response :not_found

    get buyback_requests_path(locale: :en)
    assert_response :not_found

    sign_in users(:admin)
    get admin_buyback_prices_path(locale: :en)
    assert_response :not_found

    get root_path(locale: :en)
    assert_response :success
    assert_not_includes response.body, sell_to_us_path(locale: :en)
  end

  test "the landing shows payout tables, steps, FAQ and the header link" do
    get sell_to_us_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("sell_to_us.hero.title", locale: :en)
    assert_includes response.body, @gpu_price.component_model
    assert_includes response.body, @cpu_price.component_model
    assert_includes response.body, I18n.t("sell_to_us.how.steps.offer.title", locale: :en)
    assert_includes response.body, I18n.t("sell_to_us.faq.items.payment.question", locale: :en)
    assert_includes response.body, sell_to_us_path(locale: :en)
  end

  test "anonymous visitors get an instant quote and are asked to sign in to accept" do
    post buyback_quotes_path(locale: :en), params: {
      component_type: "gpu", buyback_price_id: @gpu_price.id,
      condition: "good", powers_on: "1", artifacts: "0",
      original_box: "1", physical_damage: "0"
    }

    quote = BuybackQuote.last
    assert_redirected_to buyback_quote_path(quote.token, locale: :en)
    assert_equal 25_500, quote.offer_cents

    follow_redirect!
    assert_response :success
    assert_includes response.body, I18n.t("buyback.quote.offer_title", locale: :en)
    assert_includes response.body, "255"

    get buyback_requests_path(locale: :en)
    assert_redirected_to new_user_session_path
  end

  test "signed-in users accept a quote, provide an IBAN and create a trade-in" do
    post buyback_quotes_path(locale: :en), params: {
      component_type: "cpu", buyback_price_id: @cpu_price.id,
      condition: "fair", powers_on: "1", artifacts: "0",
      original_box: "1", physical_damage: "0"
    }
    quote = BuybackQuote.last
    sign_in users(:confirmed)

    get new_buyback_request_path(quote_id: quote.token, locale: :en)
    assert_response :success

    assert_difference "BuybackRequest.count", 1 do
      assert_enqueued_emails 1 do
        post buyback_requests_path(locale: :en, quote_id: quote.token), params: {
          buyback_request: {
            iban: "ES91 2100 0418 4502 0005 1332",
            full_name: "Mauro Ruiz", line1: "Calle Mayor 1", city: "Madrid",
            postal_code: "28001", country_code: "ES", phone: "600000000"
          }
        }
      end
    end

    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    assert_equal [ users(:confirmed).email ], email.to
    assert_includes email.text_part.body.to_s, BuybackRequest.last.reference

    request = BuybackRequest.last
    assert_redirected_to buyback_request_path(request, locale: :en)
    assert_predicate request, :accepted?
    assert_equal quote.offer_cents, request.offer_cents
    assert_equal "ES9121000418450200051332", request.iban

    follow_redirect!
    assert_response :success
    assert_includes response.body, request.reference
    assert_includes response.body, I18n.t("buyback.show.progress_title", locale: :en)
  end

  test "expired quotes cannot be accepted" do
    quote = BuybackQuote.create!(
      buyback_price: @gpu_price, component_type: :gpu, component_model: "RTX 4070",
      condition: "good", answers: {}, offer_cents: 25_500,
      expires_at: 1.day.ago
    )
    sign_in users(:confirmed)

    post buyback_requests_path(locale: :en, quote_id: quote.token), params: {
      buyback_request: { iban: "ES9121000418450200051332", full_name: "Mauro Ruiz",
                         line1: "Calle Mayor 1", city: "Madrid", postal_code: "28001",
                         country_code: "ES" }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("buyback.errors.quote_expired", locale: :en)
    assert_equal 0, BuybackRequest.count
  end
end
