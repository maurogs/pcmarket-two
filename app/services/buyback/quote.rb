# frozen_string_literal: true

module Buyback
  # Computes the instant offer: base offer × condition multiplier minus the
  # condition deductions, never below zero.
  class Quote
    DEFAULTS = {
      "powers_on" => true,
      "artifacts" => false,
      "original_box" => true,
      "physical_damage" => false
    }.freeze

    DEDUCTIONS = {
      does_not_power_on: 0.40,
      artifacts: 0.15,
      no_original_box: 0.05,
      physical_damage: 0.25
    }.freeze

    def initialize(price:, condition:, answers: {})
      @price = price
      @condition = condition.to_s
      @answers = DEFAULTS.merge(answers.to_h.stringify_keys)
    end

    def base_cents
      @price.base_offer_cents.to_i
    end

    def multiplier
      @price.condition_multiplier(@condition)
    end

    def offer_cents
      value = (base_cents * multiplier).round
      deductions.each do |key|
        value -= (base_cents * DEDUCTIONS.fetch(key)).round
      end
      [ value, 0 ].max
    end

    def deductions
      [].tap do |list|
        list << :does_not_power_on unless truthy?(@answers["powers_on"])
        list << :artifacts if truthy?(@answers["artifacts"])
        list << :no_original_box unless truthy?(@answers["original_box"])
        list << :physical_damage if truthy?(@answers["physical_damage"])
      end
    end

    private

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
