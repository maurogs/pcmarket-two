# frozen_string_literal: true

module Admin
  # Filtered store directory with the values used by the stores index.
  class StoreQuery
    include Filterable

    STORE_KINDS = Store.kinds.keys
    STORE_STATUSES = Store.statuses.keys

    def filters
      {
        q: text_param(:q),
        kind: enum_param(:kind, STORE_KINDS),
        status: enum_param(:status, STORE_STATUSES),
        verified: boolean_param(:verified),
        payouts_ready: boolean_param(:payouts_ready),
        vacation: boolean_param(:vacation),
        rating_min: decimal_param(:rating_min),
        rating_max: decimal_param(:rating_max)
      }
    end

    def relation
      @relation ||= apply_filters(
        Store.includes(:user, { logo_attachment: :blob }).joins(:user)
      )
    end

    def sort_options
      {
        "created_at" => "stores.created_at",
        "name" => "stores.name",
        "rating" => "stores.rating_average",
        "listings" => "stores.listings_count",
        "followers" => "stores.followers_count"
      }
    end

    def default_sort
      "created_at"
    end

    private

    def apply_filters(scope)
      scope = filter_by_query(scope)
      scope = scope.where(kind: filters[:kind]) if filters[:kind]
      scope = scope.where(status: filters[:status]) if filters[:status]
      scope = filter_by_verified(scope)
      scope = filter_by_payouts(scope)
      scope = filter_by_vacation(scope)
      filter_by_rating(scope)
    end

    def filter_by_query(scope)
      query = filters[:q]
      return scope if query.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      scope.where(
        "stores.name ILIKE :q OR stores.slug ILIKE :q OR stores.legal_name ILIKE :q OR users.email ILIKE :q",
        q: pattern
      )
    end

    def filter_by_verified(scope)
      case filters[:verified]
      when true then scope.where.not(verified_at: nil)
      when false then scope.where(verified_at: nil)
      else scope
      end
    end

    def filter_by_payouts(scope)
      case filters[:payouts_ready]
      when true then scope.where(payouts_enabled: true)
      when false then scope.where(payouts_enabled: false)
      else scope
      end
    end

    def filter_by_vacation(scope)
      case filters[:vacation]
      when true then scope.where(vacation_mode: true)
      when false then scope.where(vacation_mode: false)
      else scope
      end
    end

    def filter_by_rating(scope)
      min = filters[:rating_min]
      max = filters[:rating_max]
      return scope if min.nil? && max.nil?

      scope = scope.where("stores.rating_average >= ?", min) if min
      scope = scope.where("stores.rating_average <= ?", max) if max
      scope
    end

    def decimal_param(key)
      BigDecimal(text_param(key, max: 8).to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
