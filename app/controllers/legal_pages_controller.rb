# frozen_string_literal: true

class LegalPagesController < ApplicationController
  def index
    @country = current_country
    @pages = LegalPage.current_pages(country: @country, locale: I18n.locale)
    raise ActiveRecord::RecordNotFound if @pages.empty?
  end

  def show
    @country = current_country
    kind = params[:kind].to_s
    raise ActiveRecord::RecordNotFound unless LegalPage::KINDS.include?(kind)

    @page = LegalPage.current(country: @country, locale: I18n.locale, kind: kind)
    raise ActiveRecord::RecordNotFound if @page.blank?
  end
end
