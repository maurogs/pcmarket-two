# frozen_string_literal: true

module AttributeOptions
  # Bulk-creates options from a pasted list, one value per line. Existing values
  # are left untouched so importing twice is safe.
  class Import
    Result = Struct.new(:created, :skipped, keyword_init: true)

    def initialize(definition:, text:)
      @definition = definition
      @text = text.to_s
    end

    def call
      created = 0
      skipped = 0
      next_position = (@definition.attribute_options.maximum(:position) || 0) + 1

      values.each do |value|
        option = @definition.attribute_options.find_or_initialize_by(value: value)
        if option.persisted?
          skipped += 1
          next
        end

        option.position = next_position
        option.label_es = value
        option.label_en = value
        option.save!
        created += 1
        next_position += 1
      end

      Result.new(created: created, skipped: skipped)
    end

    private

    def values
      @text.lines.map { |line| line.strip }.reject(&:blank?).uniq.first(500)
    end
  end
end
