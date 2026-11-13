# frozen_string_literal: true

module Admin
  class LegalPagePublicationsController < AdminOnlyController
    def create
      page = LegalPage.find(params[:legal_page_id])
      authorize page, :publish?, policy_class: Admin::LegalPagePolicy

      unless page.draft?
        redirect_to admin_legal_page_path(page),
                    alert: t("admin.legal_pages.flash.already_published")
        return
      end

      effective_at = parse_time(params[:effective_at]) || Time.current
      page.publish!(effective_at: effective_at)
      audit!(action: "legal_page.published", auditable: page,
             changes: { effective_at: page.effective_at })
      redirect_to admin_legal_page_path(page),
                  notice: t("admin.legal_pages.flash.published")
    rescue ActiveRecord::RecordInvalid => error
      redirect_to admin_legal_page_path(page),
                  alert: error.record.errors.full_messages.to_sentence
    end

    private

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
