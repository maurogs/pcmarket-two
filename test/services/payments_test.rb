# frozen_string_literal: true

require "test_helper"

class PaymentsTest < ActiveSupport::TestCase
  test "test environment always uses the fake gateway" do
    with_stub(Payments, :stripe_secret_key, "sk_test_123") do
      with_stub(Payments, :stripe_publishable_key, "pk_test_123") do
        assert_instance_of Payments::FakeGateway, Payments.gateway
        assert Payments.fake_gateway?
      end
    end
  end

  test "development without keys uses the fake gateway" do
    with_stub(Payments, :stripe_secret_key, nil) do
      with_stub(Payments, :stripe_publishable_key, nil) do
        with_stub(Rails, :env, ActiveSupport::StringInquirer.new("development")) do
          assert_instance_of Payments::FakeGateway, Payments.gateway
          assert Payments.fake_gateway?
          assert Payments.test_mode_banner?
        end
      end
    end
  end

  test "development with keys uses the Stripe gateway and hides the test banner" do
    with_stub(Payments, :stripe_secret_key, "sk_test_123") do
      with_stub(Payments, :stripe_publishable_key, "pk_test_123") do
        with_stub(Rails, :env, ActiveSupport::StringInquirer.new("development")) do
          assert_instance_of Payments::StripeGateway, Payments.gateway
          assert_not Payments.fake_gateway?
          assert_not Payments.test_mode_banner?
        end
      end
    end
  end

  test "production with keys uses the Stripe gateway" do
    with_stub(Payments, :stripe_secret_key, "sk_live_123") do
      with_stub(Payments, :stripe_publishable_key, "pk_live_123") do
        assert_instance_of Payments::StripeGateway, Payments.gateway(env: "production")
      end
    end
  end

  test "production without keys raises a configuration error" do
    with_stub(Payments, :stripe_secret_key, nil) do
      with_stub(Payments, :stripe_publishable_key, nil) do
        assert_raises(Payments::ConfigurationError) do
          Payments.gateway(env: "production")
        end
      end
    end
  end

  test "stripe configuration requires both keys" do
    with_stub(Payments, :stripe_secret_key, "sk_test_123") do
      with_stub(Payments, :stripe_publishable_key, nil) do
        assert_not Payments.stripe_configured?
      end
    end
  end
end
