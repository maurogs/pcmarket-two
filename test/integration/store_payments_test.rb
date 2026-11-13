# frozen_string_literal: true

require "test_helper"

class StorePaymentsTest < ActionDispatch::IntegrationTest
  setup do
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    sign_in @seller
  end

  test "the payout page explains the simulated test mode" do
    get store_payment_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("store_payments.show.title", locale: :en)
    assert_includes response.body, I18n.t("store_payments.show.test_mode", locale: :en)
    assert_includes response.body, I18n.t("store_payments.show.not_configured", locale: :en)
  end

  test "the store settings tabs link to profile and payouts" do
    get edit_store_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("stores.tabs.profile", locale: :en)
    assert_includes response.body, I18n.t("stores.tabs.payments", locale: :en)
    assert_includes response.body, store_payment_path(locale: :en)
  end

  test "payout status shows the requirements Stripe still needs" do
    @store.update!(details_submitted: true, payouts_enabled: false,
                   requirements: { "currently_due" => [ "external_account", "business_profile.mcc" ] })

    with_stub(Payments, :fake_gateway?, false) do
      get store_payment_path(locale: :en)
    end

    assert_response :success
    assert_includes response.body, I18n.t("store_payments.show.statuses.action_required", locale: :en)
    assert_includes response.body, I18n.t("store_payments.requirements.external_account", locale: :en)
    assert_includes response.body, I18n.t("store_payments.requirements.business_profile.mcc", locale: :en)
    assert_includes response.body, I18n.t("store_payments.show.explanation", locale: :en)
    assert_includes response.body, I18n.t("store_payments.show.setup", locale: :en)
  end

  test "payout setup creates a Connect account and redirects to Stripe" do
    account = Struct.new(:id, :requirements).new(
      "acct_new_123", { "currently_due" => [ "external_account" ] }
    )
    link = Struct.new(:url).new("https://connect.stripe.com/setup/test")
    captured_account = nil
    captured_link = nil

    account_creator = lambda do |params, _options = {}|
      captured_account = params
      account
    end
    link_creator = lambda do |params, _options = {}|
      captured_link = params
      link
    end

    with_stub(Payments, :fake_gateway?, false) do
      with_stub(Stripe::Account, :create, account_creator) do
        with_stub(Stripe::AccountLink, :create, link_creator) do
          post store_payment_path(locale: :en)
        end
      end
    end

    assert_redirected_to "https://connect.stripe.com/setup/test"
    @store.reload
    assert_equal "acct_new_123", @store.stripe_account_id
    assert_equal [ "external_account" ], @store.requirements["currently_due"]

    assert_equal "express", captured_account[:type]
    assert_equal "ES", captured_account[:country]
    assert_equal @seller.email, captured_account[:email]
    assert_equal "individual", captured_account[:business_type]
    assert_equal({ requested: true }, captured_account[:capabilities][:transfers])

    assert_equal "acct_new_123", captured_link[:account]
    assert_equal "account_onboarding", captured_link[:type]
    assert_includes captured_link[:return_url], "/en/store/payment"
  end

  test "a business store onboards as a company" do
    @store.update!(kind: :business, legal_name: "Mauro SL", tax_id: "B12345674",
                   postal_code: "28001")
    account = Struct.new(:id, :requirements).new("acct_business_123", {})
    captured = nil
    creator = lambda do |params, _options = {}|
      captured = params
      account
    end

    with_stub(Payments, :fake_gateway?, false) do
      with_stub(Stripe::Account, :create, creator) do
        with_stub(Stripe::AccountLink, :create, Struct.new(:url).new("https://connect.stripe.com/setup/business")) do
          post store_payment_path(locale: :en)
        end
      end
    end

    assert_equal "company", captured[:business_type]
    assert_equal "acct_business_123", @store.reload.stripe_account_id
  end

  test "users without a store are sent to store onboarding" do
    sign_out @seller
    sign_in users(:moderator)

    get store_payment_path(locale: :en)

    assert_redirected_to new_store_path(locale: :en)
  end
end
