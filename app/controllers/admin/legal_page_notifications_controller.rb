# frozen_string_literal: true

module Admin
  class LegalPageNotificationsController < AdminOnlyController
    def create
      page = LegalPage.find(params[:legal_page_id])
      authorize page, :notify?, policy_class: Admin::LegalPagePolicy

      unless page.published? && page.notifiable?
        redirect_to admin_legal_page_path(page),
                    alert: t("admin.legal_pages.flash.not_notifiable")
        return
      end

      page.notify_users!
      audit!(action: "legal_page.notified", auditable: page,
             changes: { country_code: page.country_code, notified_at: page.notified_at })
      redirect_to admin_legal_page_path(page),
                  notice: t("admin.legal_pages.flash.notification_queued")
    end
  end
end
