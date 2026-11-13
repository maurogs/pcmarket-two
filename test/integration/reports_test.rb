# frozen_string_literal: true

require "test_helper"

class ReportsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs
    @listing = listings(:published_gpu)
    @reporter = users(:seller_two)
  end

  def report!(reportable: @listing, reporter: @reporter, reason: "scam_fraud", **attrs)
    Report.create!({
      reporter: reporter,
      reportable: reportable,
      reason: reason,
      details: "This item looks fraudulent and needs a manual review."
    }.merge(attrs))
  end

  test "a signed-in user can report a listing and receives an acknowledgement" do
    sign_in @reporter

    assert_difference -> { Report.count }, 1 do
      assert_enqueued_emails 1 do
        post reports_path(locale: :en), params: {
          report: {
            reportable_type: "Listing",
            reportable_id: @listing.id,
            reason: "scam_fraud",
            details: "The seller is asking for payment outside the platform."
          }
        }
      end
    end

    assert_redirected_to root_path(locale: :en)
    report = Report.last
    assert_equal @reporter, report.reporter
    assert report.open?
  end

  test "an anonymous visitor can report with an email address" do
    assert_difference -> { Report.count }, 1 do
      assert_enqueued_emails 1 do
        post reports_path(locale: :en), params: {
          report: {
            reportable_type: "Listing",
            reportable_id: @listing.id,
            reporter_email: "anonymous@example.com",
            reason: "counterfeit",
            details: "This product is clearly a counterfeit copy of the original."
          }
        }
      end
    end

    report = Report.last
    assert report.anonymous?
    assert_equal "anonymous@example.com", report.reporter_email
  end

  test "anonymous reports require a valid email and enough detail" do
    assert_no_difference -> { Report.count } do
      post reports_path(locale: :en), params: {
        report: {
          reportable_type: "Listing",
          reportable_id: @listing.id,
          reporter_email: "nope",
          reason: "spam",
          details: "too short"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "the report form shows the reported item" do
    get new_report_path(locale: :en, reportable_type: "Listing", reportable_id: @listing.id)

    assert_response :success
    assert_includes response.body, @listing.title
    assert_includes response.body, I18n.t("reports.new.title", locale: :en)
  end

  test "admins see the filtered report queue oldest first" do
    older = report!(reason: "spam")
    newer = report!(reason: "counterfeit")
    sign_in users(:admin)

    get admin_reports_path(locale: :en)

    assert_response :success
    assert_operator response.body.index("##{older.id}"), :<, response.body.index("##{newer.id}")

    get admin_reports_path(locale: :en, reason: "counterfeit")

    assert_response :success
    assert_includes response.body, "##{newer.id}"
    assert_not_includes response.body, "##{older.id}"
  end

  test "taking action archives the listing and emails the reporter" do
    report = report!
    sign_in users(:admin)

    assert_enqueued_emails 1 do
      patch admin_report_path(report, locale: :en),
            params: { decision: "action", resolution_note: "Listing removed for fraud." }
    end

    assert_redirected_to admin_report_path(report, locale: :en)
    assert report.reload.actioned?
    assert_equal "Listing removed for fraud.", report.resolution_note
    assert @listing.reload.archived?
  end

  test "dismissing a report keeps the listing and notifies the reporter" do
    report = report!
    sign_in users(:admin)

    assert_enqueued_emails 1 do
      patch admin_report_path(report, locale: :en),
            params: { decision: "dismiss", resolution_note: "No policy violation found." }
    end

    assert report.reload.dismissed?
    assert @listing.reload.published?
  end

  test "taking action on a message hides it" do
    conversation = Conversation.create!(listing: @listing, buyer: @reporter,
                                        seller: @listing.seller, store: @listing.store)
    message = conversation.messages.create!(sender: @reporter, body: "Send me money outside PCMarket")
    report = report!(reportable: message, reason: "scam_fraud")
    sign_in users(:admin)

    patch admin_report_path(report, locale: :en),
          params: { decision: "action", resolution_note: "Off-platform payment request." }

    assert message.reload.hidden_at.present?
  end

  test "taking action on a user bans the account" do
    report = report!(reportable: @reporter, reason: "harassment")
    sign_in users(:admin)

    patch admin_report_path(report, locale: :en),
          params: { decision: "action", resolution_note: "Repeated harassment." }

    assert @reporter.reload.banned?
    assert_equal "Repeated harassment.", @reporter.ban_reason
  end

  test "resolving without a statement of reasons is rejected" do
    report = report!
    sign_in users(:admin)

    patch admin_report_path(report, locale: :en), params: { decision: "action", resolution_note: "" }

    assert report.reload.open?
    assert_equal I18n.t("admin.reports.notices.invalid", locale: :en), flash[:alert]
  end
end
