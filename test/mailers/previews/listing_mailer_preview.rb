# frozen_string_literal: true

class ListingMailerPreview < ActionMailer::Preview
  def approved
    ListingMailer.approved(preview_listing)
  end

  def rejected
    listing = preview_listing
    listing.rejection_reason ||= I18n.t("admin.moderation.reasons.poor_photos", locale: :es)
    ListingMailer.rejected(listing)
  end

  private

  def preview_listing
    Listing.with_detail_includes.first || raise("Create a listing to preview moderation emails")
  end
end
