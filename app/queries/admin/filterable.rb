# frozen_string_literal: true

module Admin
  # Shared parameter normalisation, sorting, per-page selection and Pagy
  # pagination for the admin index query objects.
  module Filterable
    PER_PAGE_OPTIONS = [ 25, 50, 100 ].freeze
    DEFAULT_PER_PAGE = 25
    CSV_LIMIT = 50_000

    def initialize(params: {})
      raw = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      @params = raw.deep_stringify_keys
    end

    def filters
      {}
    end

    def sort
      @sort ||= sort_param(sort_options, default_sort)
    end

    def direction
      @direction ||= direction_param
    end

    def per_page
      @per_page ||= begin
        value = Integer(text_param(:per_page).to_s, exception: false)
        PER_PAGE_OPTIONS.include?(value) ? value : DEFAULT_PER_PAGE
      end
    end

    def pagy
      @pagy ||= begin
        total = relation.count
        last_page = [ (total.to_f / per_page).ceil, 1 ].max
        Pagy.new(count: total, page: [ page_number, last_page ].min, limit: per_page)
      end
    end

    # Subclasses provide the filtered relation.
    def relation
      raise NotImplementedError
    end

    # Subclasses provide a hash of sort key => SQL fragment.
    def sort_options
      { "created_at" => "created_at" }
    end

    def default_sort
      "created_at"
    end

    def records
      @records ||= relation.order(order_sql).offset(pagy.offset).limit(pagy.limit).to_a
    end

    # Rows for the CSV export, capped so a huge dataset cannot exhaust memory.
    def export_records
      relation.order(order_sql).limit(CSV_LIMIT)
    end

    protected

    attr_reader :params

    def text_param(key, max: 120)
      raw = params[key.to_s]
      return if raw.is_a?(Array) || raw.is_a?(Hash)

      raw.to_s.strip.presence&.slice(0, max)
    end

    def enum_param(key, allowed)
      value = text_param(key)
      allowed.include?(value) ? value : nil
    end

    def integer_param(key)
      raw = text_param(key, max: 20)
      return if raw.blank?

      Integer(raw, exception: false)
    end

    def date_param(key)
      raw = text_param(key, max: 10)
      return if raw.blank?

      Date.iso8601(raw)
    rescue Date::Error
      nil
    end

    def boolean_param(key)
      raw = params[key.to_s]
      return nil unless raw.is_a?(String) || raw == true || raw == false

      ActiveModel::Type::Boolean.new.cast(raw)
    end

    def page_number
      value = Integer(text_param(:page).to_s, exception: false)
      value && value.positive? ? value : 1
    end

    def sort_param(options, default)
      key = text_param(:sort, max: 40)
      options.key?(key) ? key : default
    end

    def direction_param
      text_param(:direction, max: 4) == "asc" ? "asc" : "desc"
    end

    def order_sql
      column = sort_options.fetch(sort, sort_options.fetch(default_sort))
      column = Arel::Nodes::SqlLiteral.new(column.to_s)
      direction == "asc" ? column.asc : column.desc
    end
  end
end
