# frozen_string_literal: true

module Admin
  # Counts how many listings use each stored value of one attribute definition.
  # A single SQL statement expands both scalar and array shapes from the jsonb
  # specs column, so the options screen never runs a query per option.
  class AttributeUsage
    def self.for(definition)
      return {} if definition.blank? || definition.key.blank?

      sql = <<~SQL
        SELECT usage.value, COUNT(DISTINCT listings.id) AS listings_count
        FROM listings,
             LATERAL (
               SELECT jsonb_array_elements_text(listings.specs -> :key) AS value
               WHERE jsonb_typeof(listings.specs -> :key) = 'array'
               UNION ALL
               SELECT listings.specs ->> :key AS value
               WHERE listings.specs ? :key
                 AND jsonb_typeof(listings.specs -> :key) <> 'array'
             ) usage
        WHERE usage.value IS NOT NULL
        GROUP BY usage.value
      SQL

      definition.class.connection.select_rows(
        ActiveRecord::Base.sanitize_sql_array([ sql, { key: definition.key } ])
      ).to_h { |value, count| [ value, count.to_i ] }
    end
  end
end
