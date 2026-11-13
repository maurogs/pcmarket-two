# frozen_string_literal: true

module Admin
  class LegalPageVersionsController < AdminOnlyController
    def create
      page = LegalPage.find(params[:legal_page_id])
      authorize page, :create_version?, policy_class: Admin::LegalPagePolicy

      source = LegalPage.latest_for(page) || page
      version = LegalPages::CreateVersion.new(page: source, version: params[:version]).call
      audit!(action: "legal_page.version_created", auditable: version,
             changes: { source_id: source.id, version: version.version })
      redirect_to edit_admin_legal_page_path(version),
                  notice: t("admin.legal_pages.flash.version_created",
                            version: version.version)
    end
  end
end
