# frozen_string_literal: true

require "test_helper"

class BuybackQuoteTest < ActiveSupport::TestCase
  setup do
    @price = BuybackPrice.create!(component_type: :gpu, component_model: "RTX 4070",
                                  base_offer_cents: 30_000)
  end

  test "applies the condition multiplier" do
    assert_equal 30_000, Buyback::Quote.new(price: @price, condition: "like_new").offer_cents
    assert_equal 25_500, Buyback::Quote.new(price: @price, condition: "good").offer_cents
    assert_equal 21_000, Buyback::Quote.new(price: @price, condition: "fair").offer_cents
    assert_equal 7_500, Buyback::Quote.new(price: @price, condition: "for_parts").offer_cents
  end

  test "subtracts each declared condition problem" do
    quote = Buyback::Quote.new(
      price: @price, condition: "like_new",
      answers: { powers_on: "1", artifacts: "1", original_box: "0", physical_damage: "1" }
    )

    # 30000 - 4500 (artefacts) - 1500 (no box) - 7500 (damage)
    assert_equal 16_500, quote.offer_cents
    assert_equal %i[artifacts no_original_box physical_damage], quote.deductions
  end

  test "never goes below zero" do
    cheap = BuybackPrice.create!(component_type: :cpu, component_model: "Old CPU",
                                 base_offer_cents: 1_000)
    quote = Buyback::Quote.new(price: cheap, condition: "for_parts",
                               answers: { powers_on: "0", artifacts: "1",
                                          original_box: "0", physical_damage: "1" })

    assert_equal 0, quote.offer_cents
    assert_includes quote.deductions, :does_not_power_on
  end

  test "defaults to a working component with its box" do
    quote = Buyback::Quote.new(price: @price, condition: "like_new")

    assert_equal 30_000, quote.offer_cents
  end
end
