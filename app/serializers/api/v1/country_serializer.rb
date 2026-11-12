# frozen_string_literal: true

module Api
  module V1
    class CountrySerializer < BaseSerializer
      attributes :code, :currency, :default_locale, :position

      attribute :name, &:name
    end
  end
end
