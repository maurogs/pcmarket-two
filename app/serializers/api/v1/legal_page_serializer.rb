# frozen_string_literal: true

module Api
  module V1
    class LegalPageSerializer < BaseSerializer
      attributes :id, :kind, :title, :version, :locale, :country_code,
                 :published_at, :effective_at, :updated_at

      attribute :body_html do |page|
        page.body.to_s
      end

      attribute :body_plain do |page|
        page.plain_body
      end
    end
  end
end
