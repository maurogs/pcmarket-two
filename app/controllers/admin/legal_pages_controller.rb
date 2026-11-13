# frozen_string_literal: true

module Admin
  class LegalPagesController < AdminOnlyController
    before_action :set_page, only: %i[show edit update]

    def index
      authorize LegalPage, :index?, policy_class: Admin::LegalPagePolicy

      scope = LegalPage.includes(:country).order(:country_code, :kind, created_at: :desc)
      scope = scope.where(country_code: params[:country_code]) if params[:country_code].present?
      scope = scope.where(locale: params[:locale]) if params[:locale].present?
      scope = scope.where(kind: params[:kind]) if LegalPage.kinds.key?(params[:kind].to_s)
      scope = scope.where(status: params[:status]) if LegalPage.statuses.key?(params[:status].to_s)
      @pages = scope.to_a
      @countries = Country.order(:position, :code)
    end

    def new
      @page = LegalPage.new(country_code: "ES", locale: "es", kind: "terms", version: "1")
      authorize @page, policy_class: Admin::LegalPagePolicy
    end

    def create
      @page = LegalPage.new(page_params)
      @page.body = params.dig(:legal_page, :body)
      authorize @page, policy_class: Admin::LegalPagePolicy

      if @page.save
        audit!(action: "legal_page.created", auditable: @page, changes: @page.saved_changes)
        redirect_to admin_legal_page_path(@page),
                    notice: t("admin.legal_pages.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      authorize @page, policy_class: Admin::LegalPagePolicy
    end

    def edit
      authorize @page, policy_class: Admin::LegalPagePolicy

      unless @page.draft?
        redirect_to admin_legal_page_path(@page),
                    alert: t("admin.legal_pages.flash.published_read_only")
      end
    end

    def update
      authorize @page, policy_class: Admin::LegalPagePolicy

      if @page.published?
        redirect_to admin_legal_page_path(@page),
                    alert: t("admin.legal_pages.flash.published_read_only")
        return
      end

      if @page.update(page_params)
        audit!(action: "legal_page.updated", auditable: @page,
               changes: @page.saved_changes.except("updated_at"))
        redirect_to admin_legal_page_path(@page), notice: t("admin.legal_pages.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_page
      @page = LegalPage.find(params[:id])
    end

    def page_params
      params.require(:legal_page).permit(:country_code, :locale, :kind, :title, :version, :body)
    end
  end
end
