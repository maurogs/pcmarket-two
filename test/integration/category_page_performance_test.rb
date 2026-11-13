# frozen_string_literal: true

require "test_helper"

class CategoryPagePerformanceTest < ActionDispatch::IntegrationTest
  test "renders 24 listing cards with a bounded number of SQL queries" do
    insert_bulk_listings(categories(:gpus), count: 21, prefix: "Query count")

    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:cached]
      next if payload[:name] == "SCHEMA"
      next if payload[:sql].match?(/\A(BEGIN|COMMIT|SAVEPOINT|RELEASE SAVEPOINT)/)

      queries << payload[:sql]
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get "/en/c/graphics-cards"
    end

    assert_response :success
    assert_includes response.body, "Query count listing 0"
    assert_equal 24, Listing.visible.in_category(categories(:gpus)).count
    assert_operator queries.size, :<, 30, "Expected fewer than 30 queries, got #{queries.size}:\n#{queries.join("\n")}"
  end
end
