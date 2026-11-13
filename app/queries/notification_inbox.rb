# frozen_string_literal: true

# Owns the notification inbox query: the unread/all filter, the cached unread
# counter and manual Pagy pagination. Controllers never query Notification
# directly for this page.
class NotificationInbox
  PER_PAGE = 20
  FILTERS = %w[unread all].freeze

  def initialize(user:, params:)
    @user = user
    raw_params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    @params = raw_params.deep_stringify_keys
  end

  def call
    @filter = normalized_filter
    @unread_count = Notification.unread_count_for(@user)
    relation = filtered_relation
    @total_count = relation.count
    @pagy = build_pagy(@total_count)
    @notifications = relation
                     .offset(@pagy.offset)
                     .limit(@pagy.limit)
                     .to_a
    self
  end

  attr_reader :filter, :unread_count, :total_count, :pagy, :notifications

  private

  def filtered_relation
    relation = @user.notifications.includes(:notifiable).recent
    filter == "unread" ? relation.unread : relation
  end

  def normalized_filter
    value = @params["filter"].to_s
    FILTERS.include?(value) ? value : "all"
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
