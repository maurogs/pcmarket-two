# frozen_string_literal: true

class LegalPageVersionsController < ApplicationController
  def index
    @country = current_country
    kind = params[:kind].to_s
    raise ActiveRecord::RecordNotFound unless LegalPage::KINDS.include?(kind)

    @page = LegalPage.current(country: @country, locale: I18n.locale, kind: kind)
    raise ActiveRecord::RecordNotFound if @page.blank?

    @versions = LegalPage.published
                         .where(country_code: @country.code, locale: @page.locale, kind: kind)
                         .newest_first
                         .to_a
  end
end
