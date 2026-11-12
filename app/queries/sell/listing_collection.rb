# frozen_string_literal: true

module Sell
  # Owns the seller's own listing query: status tabs, title search, pagination
  # and the per-tab counts shown in the index. The controller only renders the
  # result; every filtering and counting rule lives here.
  class ListingCollection
    PER_PAGE = 20

    TABS = %w[active pending_review drafts rejected sold archived].freeze
    TAB_STATUSES = {
      "active" => %w[published reserved],
      "pending_review" => %w[pending_review],
      "drafts" => %w[draft],
      "rejected" => %w[rejected],
      "sold" => %w[sold],
      "archived" => %w[archived]
    }.freeze
    STATUS_TABS = TAB_STATUSES.each_with_object({}) do |(tab, statuses), mapping|
      statuses.each { |status| mapping[status] = tab }
    end.freeze

    Result = Struct.new(:listings, :pagy, :counts, :tab, :query, keyword_init: true) do
      def count_for(tab)
        counts.fetch(tab, 0)
      end

      def total_count
        counts.values.sum
      end
    end

    def initialize(user:, params:)
      @user = user
      raw_params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      @params = raw_params.deep_stringify_keys
    end

    def call
      tab = normalized_tab
      query = normalized_query
      relation = filtered_relation(tab, query)
      total = relation.count
      pagy = build_pagy(total)
      listings = relation
                 .with_card_includes
                 .order(updated_at: :desc, id: :desc)
                 .offset(pagy.offset)
                 .limit(pagy.limit)
                 .to_a

      Result.new(
        listings: listings,
        pagy: pagy,
        counts: tab_counts,
        tab: tab,
        query: query
      )
    end

    private

    def filtered_relation(tab, query)
      relation = @user.listings
      relation = relation.where(status: TAB_STATUSES.fetch(tab)) if tab
      relation = relation.where("listings.title ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(query)}%") if query.present?
      relation
    end

    # One grouped COUNT for every status, folded into the six tab counters.
    def tab_counts
      status_counts = @user.listings.group(:status).count
      TABS.index_with(0).tap do |counts|
        status_counts.each do |status, count|
          tab = STATUS_TABS[status]
          counts[tab] += count if tab
        end
      end
    end

    def normalized_tab
      value = @params["tab"].to_s
      TABS.include?(value) ? value : "active"
    end

    def normalized_query
      raw = @params["q"]
      return if raw.is_a?(Array) || raw.is_a?(Hash)

      raw.to_s.strip.presence&.slice(0, 120)
    end

    def normalized_page
      raw = @params["page"]
      return 1 unless raw.is_a?(String) || raw.is_a?(Numeric)

      value = Integer(raw, exception: false)
      value && value.positive? ? value : 1
    end

    def build_pagy(total)
      last_page = [ (total.to_f / PER_PAGE).ceil, 1 ].max
      Pagy.new(count: total, page: [ normalized_page, last_page ].min, limit: PER_PAGE)
    end
  end
end
