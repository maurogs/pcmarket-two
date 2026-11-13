# frozen_string_literal: true

# Flipper persists features and gates in PostgreSQL via flipper-active_record.
Flipper.configure do |config|
  config.adapter { Flipper::Adapters::ActiveRecord.new }
end
