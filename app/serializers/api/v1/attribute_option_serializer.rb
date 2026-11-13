# frozen_string_literal: true

module Api
  module V1
    class AttributeOptionSerializer < BaseSerializer
      attributes :id, :value, :label, :position, :popular, :active
    end
  end
end
