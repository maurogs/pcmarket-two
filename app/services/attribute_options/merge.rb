# frozen_string_literal: true

module AttributeOptions
  # Merges option A into option B. Every listing spec that stores A is rewritten
  # to B in one jsonb UPDATE (handling both scalar and array values), then A is
  # deleted.
  class Merge
    def initialize(option:, target:)
      @option = option
      @target = target
    end

    def call
      raise ArgumentError, "options belong to different definitions" unless same_definition?
      raise ArgumentError, "options must be different" if @option.id == @target.id

      updated = 0

      AttributeOption.transaction do
        updated = rewrite_specs
        @option.destroy!
      end

      Rails.cache.write(Listing::SEARCH_CACHE_VERSION_KEY, Time.current.to_f)
      updated
    end

    private

    def same_definition?
      @option.attribute_definition_id == @target.attribute_definition_id
    end

    def rewrite_specs
      key = @option.attribute_definition.key
      old_value = @option.value
      new_value = @target.value

      sql = <<~SQL
        UPDATE listings
        SET specs = jsonb_set(
          specs,
          ARRAY[:key],
          CASE
            WHEN jsonb_typeof(specs -> :key) = 'array' THEN (
              SELECT jsonb_agg(DISTINCT CASE
                WHEN element #>> '{}' = :old_value THEN :new_value
                ELSE element #>> '{}'
              END)
              FROM jsonb_array_elements(specs -> :key) AS element
            )
            ELSE to_jsonb(:new_value::text)
          END,
          false
        ),
        updated_at = CURRENT_TIMESTAMP
        WHERE specs @> :scalar::jsonb OR specs @> :array::jsonb
      SQL

      ActiveRecord::Base.connection.update(
        ActiveRecord::Base.sanitize_sql_array([
          sql,
          {
            key: key,
            old_value: old_value,
            new_value: new_value,
            scalar: { key => old_value }.to_json,
            array: { key => [ old_value ] }.to_json
          }
        ])
      )
    end
  end
end
