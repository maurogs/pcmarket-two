# frozen_string_literal: true

require "csv"

module BuybackPrices
  # Imports buyback prices from a CSV with component_type, component_model and
  # base_offer_cents columns. Existing component/model pairs are updated, so
  # the import is idempotent. `base_offer_eur` is accepted as a friendlier
  # alternative to cents.
  class Import
    Result = Struct.new(:created, :updated, :skipped, :sample, keyword_init: true)

    def initialize(text:)
      @text = text.to_s
    end

    def call
      created = 0
      updated = 0
      skipped = 0
      sample = nil

      rows.each do |row|
        type = row["component_type"].to_s.strip.downcase
        model = (row["component_model"] || row["model_name"]).to_s.strip
        cents = base_offer_cents(row)
        type = "gpu" if type == "graphics_card"
        type = "cpu" if type == "processor"

        unless %w[gpu cpu].include?(type) && model.present? && cents.positive?
          skipped += 1
          next
        end

        price = BuybackPrice.find_or_initialize_by(component_type: type, component_model: model)
        if price.new_record?
          price.base_offer_cents = cents
          price.active = true
          price.save!
          created += 1
          sample ||= price
        elsif price.base_offer_cents != cents || !price.active?
          price.update!(base_offer_cents: cents, active: true)
          updated += 1
          sample ||= price
        else
          skipped += 1
        end
      end

      Result.new(created: created, updated: updated, skipped: skipped, sample: sample)
    end

    private

    def rows
      CSV.parse(@text, headers: true).first(5_000).map(&:to_h)
    rescue CSV::MalformedCSVError
      []
    end

    def base_offer_cents(row)
      cents = row["base_offer_cents"].to_s.strip
      return cents.to_i if cents.match?(/\A\d+\z/)

      euros = row["base_offer_eur"].to_s.strip
      return 0 unless euros.match?(/\A\d+([.,]\d{1,2})?\z/)

      (BigDecimal(euros.tr(",", ".")) * 100).round
    rescue ArgumentError
      0
    end
  end
end
