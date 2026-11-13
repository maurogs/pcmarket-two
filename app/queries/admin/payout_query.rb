# frozen_string_literal: true

module Admin
  # Payouts list with the failed-transfer retry entry point.
  class PayoutQuery
    include Filterable

    FILTERABLE_STATUSES = Payout::STATUSES

    def filters
      {
        q: text_param(:q),
        status: enum_param(:status, FILTERABLE_STATUSES),
        store_id: integer_param(:store_id)
      }
    end

    def relation
      @relation ||= apply_filters(Payout.includes(:store, order: :buyer))
    end

    def sort_options
      {
        "created_at" => "payouts.created_at",
        "amount" => "payouts.amount_cents",
        "status" => "payouts.status"
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
      scope = scope.where(status: filters[:status]) if filters[:status]
      scope = scope.where(store_id: filters[:store_id]) if filters[:store_id]
      filter_by_query(scope)
    end

    def filter_by_query(scope)
      query = filters[:q]
      return scope if query.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      scope.joins(:order).where("orders.number ILIKE ?", pattern)
    end
  end
end
