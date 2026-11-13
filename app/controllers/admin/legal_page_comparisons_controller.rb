# frozen_string_literal: true

module Admin
  class LegalPageComparisonsController < AdminOnlyController
    def show
      @page = LegalPage.find(params[:legal_page_id])
      authorize @page, :compare?, policy_class: Admin::LegalPagePolicy

      @other = other_version
      @rows = @other ? LegalPages::Diff.call(@other.plain_body, @page.plain_body) : []
      render "admin/legal_pages/comparison"
    end

    private

    def other_version
      if params[:other_id].present?
        LegalPage.find_by(id: params[:other_id], country_code: @page.country_code,
                          locale: @page.locale, kind: @page.kind)
      else
        LegalPage.where(country_code: @page.country_code, locale: @page.locale,
                        kind: @page.kind)
                 .where("id <> ?", @page.id)
                 .order(created_at: :desc, id: :desc).first
      end
    end
  end
end
