# frozen_string_literal: true

require "test_helper"
require Rails.root.join("test/mailers/previews/listing_mailer_preview")

class ListingMailerTest < ActionMailer::TestCase
  setup do
    @listing = listings(:published_gpu)
    @listing.seller.update!(locale: "fr")
  end

  test "approved renders HTML and text in the seller's locale" do
    email = ListingMailer.approved(@listing)

    assert_equal [ @listing.seller.email ], email.to
    assert_equal I18n.t("listing_mailer.approved.subject", locale: :fr), email.subject
    assert_includes email.text_part.body.to_s,
                    I18n.t("listing_mailer.approved.body",
                           title: @listing.title, app: I18n.t("app.name", locale: :fr), locale: :fr)
    assert_includes email.html_part.body.to_s, I18n.t("listing_mailer.approved.cta", locale: :fr)
    assert_includes email.text_part.body.to_s, "/fr/l/"
    assert_includes email.html_part.body.to_s, "/fr/sell/"
  end

  test "rejected renders the reason and both parts in the seller's locale" do
    @listing.rejection_reason = "Photos floues"

    email = ListingMailer.rejected(@listing)

    assert_equal I18n.t("listing_mailer.rejected.subject", locale: :fr), email.subject
    assert_includes email.text_part.body.to_s, I18n.t("listing_mailer.rejected.reason_label", locale: :fr)
    assert_includes email.text_part.body.to_s, "Photos floues"
    assert_includes email.html_part.body.to_s, "Photos floues"
    assert_includes email.html_part.body.to_s, "/fr/sell/"
  end

  test "the preview exposes the approved and rejected actions" do
    preview = ListingMailerPreview.new

    assert_respond_to preview, :approved
    assert_respond_to preview, :rejected
  end
end
