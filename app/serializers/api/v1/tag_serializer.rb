# frozen_string_literal: true

module Api
  module V1
    class TagSerializer < BaseSerializer
      attributes :id, :slug, :name, :kind, :colour, :position, :active
    end
  end
end
