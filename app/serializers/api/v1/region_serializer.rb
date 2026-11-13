# frozen_string_literal: true

module Api
  module V1
    class RegionSerializer < BaseSerializer
      attributes :id, :name, :code, :country_code, :position
    end
  end
end
