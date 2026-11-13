# frozen_string_literal: true

module Settings
  # Applies the grouped admin settings form, casting each value to the type
  # declared on the Setting row. All rows are saved in one transaction.
  class Update
    Result = Struct.new(:success, :errors, :changes, keyword_init: true) do
      def success? = success
    end

    def initialize(params:)
      @params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    end

    def call
      errors = []
      changes = {}

      Setting.transaction do
        @params.each do |key, raw|
          setting = Setting.find_by(key: key.to_s)
          next if setting.blank?

          value = cast(setting.value_type, raw)
          next if setting.value == value

          old_value = setting.value
          setting.value = value
          setting.save!
          changes[setting.key] = { from: old_value, to: value }
        rescue ActiveRecord::RecordInvalid => error
          errors << error.record.errors.full_messages.to_sentence
          raise ActiveRecord::Rollback
        end
      end

      Result.new(success: errors.empty?, errors: errors, changes: changes)
    end

    private

    def cast(type, raw)
      case type
      when "boolean"
        ActiveModel::Type::Boolean.new.cast(raw)
      when "integer"
        Integer(raw.to_s, exception: false) || raw
      when "decimal"
        BigDecimal(raw.to_s, exception: false) || raw
      else
        raw.to_s
      end
    end
  end
end
