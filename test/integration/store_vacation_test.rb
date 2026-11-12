# frozen_string_literal: true

require "test_helper"

class StoreVacationTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
  end

  test "a seller can turn vacation mode on with a return date and schedule the auto-off job" do
    sign_in @seller
    return_date = Date.current + 3.days

    assert_enqueued_with(job: Stores::VacationAutoOffJob) do
      patch store_vacation_path(locale: :en), params: {
        store: {
          vacation_mode: "1",
          vacation_message: "Back after a short break.",
          vacation_until: return_date
        }
      }
    end

    assert_redirected_to store_vacation_path(locale: :en)
    @store.reload
    assert @store.vacation_mode?
    assert_equal return_date, @store.vacation_until
    assert_equal "Back after a short break.", @store.vacation_message
  end

  test "the auto-off job turns vacation mode off on the return date" do
    @store.update!(vacation_mode: true, vacation_until: Date.current)

    Stores::VacationAutoOffJob.perform_now(@store.id, Date.current)

    @store.reload
    assert_not @store.vacation_mode?
    assert_nil @store.vacation_until
  end

  test "the auto-off job ignores a stale schedule for another date" do
    @store.update!(vacation_mode: true, vacation_until: Date.current + 5.days)

    Stores::VacationAutoOffJob.perform_now(@store.id, Date.current)

    assert @store.reload.vacation_mode?
  end

  test "vacation listings show a banner and keep checkout blocked" do
    @store.update!(vacation_mode: true, vacation_message: "Away until Monday.")

    get listing_path(listings(:published_gpu), locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("storefronts.vacation.title", locale: :en)
    assert_includes response.body, "Away until Monday."
    assert_includes response.body, "disabled"
    assert_includes response.body, I18n.t("cart.purchase_blocked.store_vacation", locale: :en)
  end
end
