# frozen_string_literal: true

require "csv"

module Admin
  # Streams a CSV of the current filtered set. Rows are produced lazily so the
  # response can start before the whole file has been rendered. Callers pass a
  # relation already capped by the query object (50k rows maximum).
  class CsvExport
    def initialize(headers:, rows:)
      @headers = headers
      @rows = rows
    end

    def to_csv
      CSV.generate do |csv|
        csv << @headers
        @rows.each { |row| csv << row }
      end
    end

    def to_enum
      Enumerator.new do |yielder|
        yielder << CSV.generate_line(@headers)
        @rows.each do |row|
          yielder << CSV.generate_line(row)
        end
      end
    end
  end
end
