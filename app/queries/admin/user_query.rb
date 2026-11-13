# frozen_string_literal: true

module Admin
  # Filtered user directory. Moderators can only read it; mutations are
  # admin-only through Admin::UserPolicy.
  class UserQuery
    include Filterable

    ROLES = User.roles.keys
    STATUSES = %w[active banned deleted unconfirmed].freeze

    def filters
      {
        q: text_param(:q),
        role: enum_param(:role, ROLES),
        status: enum_param(:status, STATUSES),
        has_store: boolean_param(:has_store),
        created_from: date_param(:created_from),
        created_to: date_param(:created_to),
        last_sign_in_from: date_param(:last_sign_in_from),
        last_sign_in_to: date_param(:last_sign_in_to)
      }
    end

    def relation
      @relation ||= apply_filters(User.includes({ store: { logo_attachment: :blob } }))
    end

    def sort_options
      {
        "created_at" => "users.created_at",
        "updated_at" => "users.updated_at",
        "email" => "users.email",
        "username" => "users.username",
        "last_sign_in_at" => "users.last_sign_in_at",
        "sign_in_count" => "users.sign_in_count"
      }
    end

    def default_sort
      "created_at"
    end

    private

    def apply_filters(scope)
      scope = filter_by_query(scope)
      scope = scope.where(role: filters[:role]) if filters[:role]
      scope = filter_by_status(scope)
      scope = filter_by_store(scope)
      scope = filter_by_created(scope)
      filter_by_sign_in(scope)
    end

    def filter_by_query(scope)
      query = filters[:q]
      return scope if query.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      scope.where(
        "users.email ILIKE :q OR users.username ILIKE :q OR " \
        "users.first_name ILIKE :q OR users.last_name ILIKE :q",
        q: pattern
      )
    end

    def filter_by_status(scope)
      case filters[:status]
      when "active" then scope.where(banned_at: nil, deleted_at: nil)
      when "banned" then scope.where.not(banned_at: nil)
      when "deleted" then scope.where.not(deleted_at: nil)
      when "unconfirmed" then scope.where(confirmed_at: nil)
      else scope
      end
    end

    def filter_by_store(scope)
      case filters[:has_store]
      when true then scope.where(id: Store.select(:user_id))
      when false then scope.where.not(id: Store.select(:user_id))
      else scope
      end
    end

    def filter_by_created(scope)
      range = date_range(filters[:created_from], filters[:created_to])
      range ? scope.where(created_at: range) : scope
    end

    def filter_by_sign_in(scope)
      range = date_range(filters[:last_sign_in_from], filters[:last_sign_in_to])
      range ? scope.where(last_sign_in_at: range) : scope
    end

    def date_range(from, to)
      return if from.nil? && to.nil?

      (from || Date.new(1970, 1, 1))..(to || Date.current)
    end
  end
end
