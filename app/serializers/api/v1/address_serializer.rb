# frozen_string_literal: true

module Api
  module V1
    class AddressSerializer < BaseSerializer
      attributes :id, :full_name, :line1, :line2, :city, :region_id,
                 :postal_code, :country_code, :phone, :default, :created_at,
                 :updated_at

      attribute :province_name, &:province_name
    end
  end
end
