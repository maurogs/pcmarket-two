# frozen_string_literal: true

module Admin
  # Filtered order list for the admin panel.
  class OrderQuery
    include Filterable

    FILTERABLE_STATUSES = Order::STATUSES
    FILTERABLE_FULFILMENTS = Order.fulfilments.keys

    def filters
      {
        q: text_param(:q),
        status: enum_param(:status, FILTERABLE_STATUSES),
        store_id: integer_param(:store_id),
        buyer_id: integer_param(:buyer_id),
        date_from: date_param(:date_from),
        date_to: date_param(:date_to),
        amount_min: money_param(:amount_min),
        amount_max: money_param(:amount_max),
        fulfilment: enum_param(:fulfilment, FILTERABLE_FULFILMENTS),
        disputed: boolean_param(:disputed)
      }
    end

    def relation
      @relation ||= apply_filters(
        Order.includes(:buyer, :store, :payout).joins(:store)
      )
    end

    def sort_options
      {
        "created_at" => "orders.created_at",
        "total" => "orders.total_cents",
        "number" => "orders.number",
        "status" => "orders.status"
      }
    end

    def default_sort
      "created_at"
    end

    def stores
      @stores ||= Store.order(:name).limit(500).to_a
    end

    private

    def apply_filters(scope)
      scope = filter_by_query(scope)
      scope = scope.where(status: filters[:status]) if filters[:status]
      scope = scope.where(store_id: filters[:store_id]) if filters[:store_id]
      scope = scope.where(buyer_id: filters[:buyer_id]) if filters[:buyer_id]
      scope = scope.where(fulfilment: filters[:fulfilment]) if filters[:fulfilment]
      scope = filter_by_dates(scope)
      scope = filter_by_amount(scope)
      filter_by_dispute(scope)
    end

    def filter_by_query(scope)
      query = filters[:q]
      return scope if query.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      scope.where("orders.number ILIKE ?", pattern)
    end

    def filter_by_dates(scope)
      from = filters[:date_from]
      to = filters[:date_to]
      return scope if from.nil? && to.nil?

      scope.where(created_at: (from || Date.new(1970, 1, 1))..(to || Date.current))
    end

    def filter_by_amount(scope)
      min = filters[:amount_min]
      max = filters[:amount_max]
      return scope if min.nil? && max.nil?

      scope = scope.where("orders.total_cents >= ?", (min * 100).round) if min
      scope = scope.where("orders.total_cents <= ?", (max * 100).round) if max
      scope
    end

    def filter_by_dispute(scope)
      case filters[:disputed]
      when true then scope.where(status: "disputed")
      when false then scope.where.not(status: "disputed")
      else scope
      end
    end

    def money_param(key)
      BigDecimal(text_param(key, max: 12).to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
