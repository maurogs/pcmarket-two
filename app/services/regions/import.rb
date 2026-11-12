# frozen_string_literal: true

module Regions
  # Imports "code,name" lines for one country. Existing codes are updated so
  # the operation is idempotent and safe to re-run.
  class Import
    Result = Struct.new(:created, :updated, :skipped, keyword_init: true)

    def initialize(country:, text:)
      @country = country
      @text = text.to_s
    end

    def call
      created = 0
      updated = 0
      skipped = 0
      next_position = (@country.regions.maximum(:position) || 0) + 1

      rows.each do |code, name|
        if code.blank? || name.blank?
          skipped += 1
          next
        end

        region = @country.regions.find_or_initialize_by(code: code)
        if region.new_record?
          region.name = name
          region.position = next_position
          next_position += 1
          region.save!
          created += 1
        elsif region.name != name
          region.update!(name: name)
          updated += 1
        else
          skipped += 1
        end
      end

      Result.new(created: created, updated: updated, skipped: skipped)
    end

    private

    def rows
      @text.lines.filter_map do |line|
        code, name = line.strip.split(/\s*,\s*/, 2)
        next if code.blank? || name.blank?

        [ code.strip.upcase, name.strip ]
      end.first(1_000)
    end
  end
end
