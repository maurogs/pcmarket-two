# frozen_string_literal: true

require "test_helper"

class ApiV1NotificationsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:confirmed)
    @token = issue_api_session(@user).at(1)
    @headers = api_headers(@token)
  end

  test "notifications use cursor pagination" do
    first = create_notification
    second = create_notification
    third = create_notification

    get api_v1_notifications_path, headers: @headers, params: { per_page: 2 }, as: :json

    assert_response :success
    assert_equal [ second.id, third.id ], json_data.map { |notification| notification["id"] }
    assert json_meta["has_more"]
    assert_equal second.id, json_meta["next_before_id"]

    get api_v1_notifications_path, headers: @headers,
        params: { per_page: 2, before_id: json_meta["next_before_id"] }, as: :json

    assert_response :success
    assert_equal [ first.id ], json_data.map { |notification| notification["id"] }
    assert_not json_meta["has_more"]
  end

  test "marks a single notification as read" do
    notification = create_notification

    post api_v1_notification_read_path(notification), headers: @headers, as: :json

    assert_response :success
    assert notification.reload.read_at.present?
    assert json_data["unread"] == false
  end

  test "marks all notifications as read and reports the unread count" do
    2.times { create_notification }

    get api_v1_notification_unread_count_path, headers: @headers, as: :json
    assert_response :success
    assert_equal 2, json_data["unread_count"]

    post api_v1_notification_read_all_path, headers: @headers, as: :json
    assert_response :success
    assert_equal 2, json_data["marked_read"]

    get api_v1_notification_unread_count_path, headers: @headers, as: :json
    assert_response :success
    assert_equal 0, json_data["unread_count"]
  end

  test "cannot mark another user's notification as read" do
    notification = Notification.create!(
      recipient: users(:seller_two), kind: "new_message", params: {}
    )

    post api_v1_notification_read_path(notification), headers: @headers, as: :json
    assert_response :not_found
  end

  private

  def create_notification
    Notification.create!(
      recipient: @user, kind: "new_message",
      params: { sender_name: "Ana", title: "A listing", conversation_id: 1 }
    )
  end
end
