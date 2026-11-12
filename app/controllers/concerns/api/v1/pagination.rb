# frozen_string_literal: true

module Api
  module V1
    # Page/per_page pagination with Pagy, Link and X-Total-Count headers, plus
    # the cursor pagination used by high-volume feeds (messages, notifications).
    module Pagination
      extend ActiveSupport::Concern

      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 50

      private

      def paginate(relation)
        total = relation.count
        pagy = pagy_for(total)
        records = relation.offset(pagy.offset).limit(pagy.limit).to_a
        [ pagy, records ]
      end

      def paginate_array(collection)
        total = collection.size
        pagy = pagy_for(total)
        [ pagy, collection.slice(pagy.offset, pagy.limit) || [] ]
      end

      def pagy_for(total)
        last_page = [ (total.to_f / pagination_per_page).ceil, 1 ].max
        Pagy.new(count: total, page: [ pagination_page, last_page ].min,
                 limit: pagination_per_page)
      end

      def pagination_page
        raw = params[:page]
        return 1 unless raw.is_a?(String) || raw.is_a?(Numeric)

        value = Integer(raw, exception: false)
        value && value.positive? ? value : 1
      end

      def pagination_per_page
        raw = params[:per_page]
        value = raw.is_a?(String) || raw.is_a?(Numeric) ? Integer(raw, exception: false) : nil
        return DEFAULT_PER_PAGE if value.nil? || value <= 0

        [ value, MAX_PER_PAGE ].min
      end

      def collection_meta(pagy, extra: {})
        {
          page: pagy.page,
          per_page: pagy.limit,
          total: pagy.count,
          total_pages: pagy.pages
        }.merge(extra)
      end

      def set_pagination_headers(pagy)
        response.set_header("X-Total-Count", pagy.count.to_s)
        links = link_header(pagy)
        response.set_header("Link", links) if links.present?
      end

      def link_header(pagy)
        links = []
        links << link_entry(1, "first")
        links << link_entry(pagy.prev, "prev") if pagy.prev
        links << link_entry(pagy.next, "next") if pagy.next
        links << link_entry(pagy.pages, "last")
        links.join(", ")
      end

      def link_entry(page, rel)
        query = request.query_parameters.to_h.merge("page" => page.to_s)
        url = "#{request.base_url}#{request.path}?#{query.to_query}"
        "<#{url}>; rel=\"#{rel}\""
      end

      # Returns [records_oldest_first, meta].
      def cursor_page(scope, before_id: params[:before_id])
        cursor = before_id.to_i
        scope = scope.where("id < ?", cursor) if cursor.positive?
        rows = scope.reorder(id: :desc).limit(pagination_per_page + 1).to_a
        has_more = rows.size > pagination_per_page
        rows = rows.first(pagination_per_page)
        next_before_id = has_more ? rows.last.id : nil

        [
          rows.reverse,
          { next_before_id: next_before_id, has_more: has_more,
            per_page: pagination_per_page }
        ]
      end
    end
  end
end
