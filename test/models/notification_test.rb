# frozen_string_literal: true

require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:moderator)
    clear_enqueued_jobs
  end

  test "validates the kind and the params hash" do
    notification = Notification.new(recipient: @user, kind: "not_a_kind", params: {})

    assert_not notification.valid?
    assert notification.errors[:kind].any?

    notification.kind = "new_sale"
    notification.params = "nope"
    assert_not notification.valid?
    assert notification.errors[:params].any?
  end

  test "unread and read scopes split on the read timestamp" do
    unread = Notification.create!(recipient: @user, kind: "new_sale", params: {})
    read = Notification.create!(recipient: @user, kind: "order_shipped", params: {},
                                read_at: Time.current)

    assert_equal [ unread.id ], Notification.unread.pluck(:id)
    assert_equal [ read.id ], Notification.read.pluck(:id)
  end

  test "mark_read! is idempotent" do
    notification = Notification.create!(recipient: @user, kind: "new_sale", params: {})

    assert_nil notification.read_at
    notification.mark_read!
    first_read_at = notification.read_at
    assert first_read_at.present?

    travel 1.minute do
      notification.mark_read!
    end
    assert_equal first_read_at, notification.reload.read_at
  end

  test "unread_count_for counts and expires the cached value" do
    with_cache(ActiveSupport::Cache::MemoryStore.new) do
      assert_equal 0, Notification.unread_count_for(@user)

      Notification.create!(recipient: @user, kind: "new_sale", params: {})

      assert_equal 1, Notification.unread_count_for(@user)
      assert_equal 1, Notification.where(recipient_id: @user.id, read_at: nil).count
    end
  end

  test "creating a notification enqueues a bell broadcast" do
    assert_enqueued_with(job: Turbo::Streams::ActionBroadcastJob) do
      Notification.create!(recipient: @user, kind: "new_sale", params: {})
    end
  end

  test "the bell broadcast renders in the recipient locale" do
    @user.update!(locale: "de")
    Notification.create!(recipient: @user, kind: "new_sale",
                         params: { number: "PCM-1", title: "GPU", total_cents: 1_000,
                                   currency: "EUR" })

    assert_nothing_raised do
      perform_enqueued_jobs only: Turbo::Streams::ActionBroadcastJob
    end
  end

  test "bell broadcasts carry the recipient locale" do
    @user.update!(locale: "de")

    Notification.create!(recipient: @user, kind: "new_sale", params: {})

    payload = ActiveJob::Base.queue_adapter.enqueued_jobs.last[:args]
    assert_equal "de", payload.last["locals"]["locale"]
  end

  test "marking a notification read broadcasts the updated bell" do
    notification = Notification.create!(recipient: @user, kind: "new_sale", params: {})
    clear_enqueued_jobs

    assert_enqueued_with(job: Turbo::Streams::ActionBroadcastJob) do
      notification.mark_read!
    end
  end

  test "destroying a notification broadcasts the updated bell" do
    notification = Notification.create!(recipient: @user, kind: "new_sale", params: {})
    clear_enqueued_jobs

    assert_enqueued_with(job: Turbo::Streams::ActionBroadcastJob) do
      notification.destroy!
    end
  end

  test "latest returns at most ten newest notifications" do
    12.times do |index|
      Notification.create!(recipient: @user, kind: "new_sale", params: { index: index })
    end

    latest = Notification.latest.to_a

    assert_equal 10, latest.size
    assert_equal latest.map(&:id).max, latest.first.id
  end
end
