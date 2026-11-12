# frozen_string_literal: true

require "test_helper"

class AdminBuybackRequestsTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable(:sell_to_us)
    ActionMailer::Base.deliveries.clear
    @price = BuybackPrice.create!(component_type: :gpu, component_model: "RTX 4070",
                                  base_offer_cents: 30_000)
    @quote = BuybackQuote.create!(
      buyback_price: @price, component_type: :gpu, component_model: "RTX 4070",
      condition: "good", answers: {}, offer_cents: 25_500,
      expires_at: 7.days.from_now
    )
    @trade_in = BuybackRequest.create!(
      buyback_quote: @quote, user: users(:confirmed), component_type: :gpu,
      component_model: "RTX 4070", condition: "good", offer_cents: 25_500,
      iban: "ES9121000418450200051332", full_name: "Mauro Ruiz",
      line1: "Calle Mayor 1", city: "Madrid", postal_code: "28001",
      country_code: "ES"
    )
    @trade_in.accept!
    sign_in users(:admin)
  end

  teardown do
    Flipper.disable(:sell_to_us)
  end

  test "the queue lists requests and shows the detail with the timeline" do
    get admin_buyback_requests_path(locale: :en)
    assert_response :success
    assert_includes response.body, @trade_in.reference
    assert_includes response.body, @trade_in.user.display_name

    get admin_buyback_request_path(@trade_in, locale: :en)
    assert_response :success
    assert_includes response.body, I18n.t("buyback.show.progress_title", locale: :en)
    assert_includes response.body, I18n.t("admin.buyback_requests.actions.label_sent.title", locale: :en)
  end

  test "moves a request through label, receipt, revision and payout with audit and email" do
    assert_enqueued_emails 1 do
      post admin_buyback_request_events_path(@trade_in, locale: :en),
           params: { event: "label_sent", carrier: "SEUR", tracking_number: "SEUR123" }
    end
    @trade_in.reload
    assert_predicate @trade_in, :label_sent?
    assert_equal "SEUR123", @trade_in.tracking_number
    assert_equal 1, AdminAuditLog.where(action: "buyback_request.label_sent").count

    assert_enqueued_emails 1 do
      post admin_buyback_request_events_path(@trade_in, locale: :en), params: { event: "received" }
    end
    assert_predicate @trade_in.reload, :received?

    assert_enqueued_emails 1 do
      post admin_buyback_request_events_path(@trade_in, locale: :en),
           params: { event: "inspected", inspection_result: "Minor scratches",
                     revised_offer: "200" }
    end
    @trade_in.reload
    assert_predicate @trade_in, :offer_revised?
    assert_equal 20_000, @trade_in.revised_offer_cents
    assert_equal "Minor scratches", @trade_in.inspection_result

    assert_enqueued_emails 1 do
      post admin_buyback_request_events_path(@trade_in, locale: :en),
           params: { event: "accepted_revision" }
    end
    assert_predicate @trade_in.reload, :accepted?

    assert_enqueued_emails 1 do
      post admin_buyback_request_events_path(@trade_in, locale: :en), params: { event: "paid" }
    end
    assert_predicate @trade_in.reload, :paid?
  end

  test "rejects an invalid transition without changing the state" do
    post admin_buyback_request_events_path(@trade_in, locale: :en), params: { event: "received" }

    assert_redirected_to admin_buyback_request_path(@trade_in, locale: :en)
    assert_equal I18n.t("admin.buyback_requests.flash.invalid_transition", locale: :en),
                 flash[:alert]
    assert_predicate @trade_in.reload, :accepted?
  end

  test "moderators cannot reach the queue" do
    sign_in users(:moderator)

    get admin_buyback_requests_path(locale: :en)
    assert_response :not_found
  end

  test "CSV import creates and updates buyback prices" do
    assert_difference "BuybackPrice.count", 2 do
      post admin_buyback_price_imports_path(locale: :en), params: {
        text: "component_type,component_model,base_offer_cents\n" \
              "gpu,RTX 5080,90000\ncpu,Ryzen 7 7800X3D,15000\n"
      }
    end

    assert_equal 90_000, BuybackPrice.find_by!(component_model: "RTX 5080").base_offer_cents

    assert_no_difference "BuybackPrice.count" do
      post admin_buyback_price_imports_path(locale: :en), params: {
        text: "component_type,component_model,base_offer_eur\ngpu,RTX 5080,850.00\n"
      }
    end
    assert_equal 85_000, BuybackPrice.find_by!(component_model: "RTX 5080").base_offer_cents
  end
end
