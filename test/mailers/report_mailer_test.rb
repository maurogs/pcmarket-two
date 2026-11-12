# frozen_string_literal: true

require "test_helper"

class ReportMailerTest < ActionMailer::TestCase
  setup do
    @listing = listings(:published_gpu)
    @reporter = users(:seller_two)
  end

  test "acknowledgement goes to the reporter" do
    @reporter.update!(locale: "en")
    report = Report.create!(reporter: @reporter, reportable: @listing, reason: "scam_fraud",
                            details: "This listing looks fraudulent and needs a review.")

    mail = ReportMailer.acknowledgement(report)

    assert_equal [ @reporter.email ], mail.to
    assert_equal I18n.t("report_mailer.acknowledgement.subject", locale: :en), mail.subject
  end

  test "anonymous acknowledgement goes to the supplied email" do
    report = Report.create!(reporter_email: "anonymous@example.com", reportable: @listing,
                            reason: "spam", details: "This listing is spam and repeats everywhere.")

    mail = ReportMailer.acknowledgement(report)

    assert_equal [ "anonymous@example.com" ], mail.to
  end

  test "decision includes the statement of reasons" do
    report = Report.create!(reporter: @reporter, reportable: @listing, reason: "counterfeit",
                            details: "The item is a counterfeit and the seller knows it.",
                            status: "actioned", resolution_note: "Listing removed.")

    mail = ReportMailer.decision(report)

    assert_includes mail.body.encoded, "Listing removed."
    assert_equal I18n.t("report_mailer.decision.subject",
                        decision: I18n.t("report_mailer.decisions.actioned", locale: :es),
                        locale: :es),
                 mail.subject
  end
end
